local finished = false
local current = 0
local transitioning = false
local action_started = false

vim.cmd.cd("/opt/workbench/tests/fixtures")

local probes = {
  {
    name = "workbench-cache-warmup-ff",
    sources = {
      { name = "buffer" },
      { name = "file_old" },
      { name = "file_rec", params = { path = vim.fn.getcwd() } },
      { name = "line" },
      { name = "rg", params = { input = "__nvim_workbench_cache_probe__" } },
    },
  },
  {
    name = "workbench-cache-warmup-filer",
    ui = "filer",
    sources = { { name = "file" } },
    sourceOptions = { file = { path = vim.fn.getcwd() } },
  },
  {
    name = "workbench-cache-warmup-file-action",
    sources = { { name = "file_rec", params = { path = vim.fn.getcwd() } } },
  },
}

local function start_next_probe()
  if finished or current >= #probes then
    return
  end
  current = current + 1
  transitioning = false
  vim.fn["ddu#start"](probes[current])
end

local function finish()
  if finished then
    return
  end
  assert(vim.g.workbench_ddu_ready, "ddu was not configured after DenopsReady")
  assert(vim.fn["denops#plugin#is_loaded"]("ddu") == 1, "ddu denops plugin did not finish loading")
  finished = true
  print("Denops and all adopted ddu extensions cache warmup: OK")
  vim.cmd("qall!")
end

vim.api.nvim_create_autocmd("User", {
  pattern = "Ddu:uiReady",
  callback = function()
    vim.schedule(function()
      if finished or transitioning then
        return
      elseif current < #probes then
        transitioning = true
        vim.fn["ddu#ui_sync_action"](probes[current].name, "quit")
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "Ddu:uiDone",
  callback = function()
    if current == #probes and not finished and not action_started then
      action_started = true
      vim.schedule(function()
        vim.fn["ddu#ui#do_action"]("itemAction", { name = "open" })
        finish()
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "Ddu:uiQuit",
  callback = function()
    if transitioning then
      vim.schedule(start_next_probe)
    end
  end,
})

vim.api.nvim_create_autocmd("User", {
  pattern = "DenopsPluginPost:ddu",
  once = true,
  callback = function()
    vim.schedule(start_next_probe)
  end,
})

if vim.fn.exists("*denops#plugin#is_loaded") == 1 and vim.fn["denops#plugin#is_loaded"]("ddu") == 1 then
  vim.schedule(start_next_probe)
end

vim.defer_fn(function()
  if not finished then
    print("adopted ddu extensions timed out during cache warmup")
    vim.cmd("cquit 1")
  end
end, 120000)
