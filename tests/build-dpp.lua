local base = vim.fn.stdpath("data") .. "/dpp"
local repos = base .. "/repos/github.com"
local config = vim.fn.stdpath("config") .. "/dpp/load_plugins.ts"
local phase = assert(vim.env.DPP_BUILD_PHASE, "DPP_BUILD_PHASE is required")

for _, path in ipairs({
  repos .. "/Shougo/dpp.vim",
  repos .. "/vim-denops/denops.vim",
  repos .. "/Shougo/dpp-ext-installer",
  repos .. "/Shougo/dpp-ext-lazy",
  repos .. "/Shougo/dpp-ext-toml",
  repos .. "/Shougo/dpp-protocol-git",
}) do
  assert(vim.uv.fs_stat(path), "missing dpp core repository: " .. path)
  vim.opt.runtimepath:prepend(path)
end

local dpp = require("dpp")
local finished = false
local function finish(message)
  if finished then
    return
  end
  finished = true
  print(message)
  vim.cmd("qall!")
end

vim.defer_fn(function()
  if not finished then
    print("dpp build phase timed out: " .. phase)
    vim.cmd("cquit 1")
  end
end, 180000)

if phase == "state" then
  dpp.load_state(base)
  vim.api.nvim_create_autocmd("User", {
    pattern = "Dpp:makeStatePost",
    once = true,
    callback = function()
      finish("dpp state generated")
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "DenopsReady",
    once = true,
    callback = function()
      local ok, err = pcall(dpp.make_state, base, config)
      if not ok then
        print("dpp.make_state failed: " .. tostring(err))
        vim.cmd("cquit 1")
      end
    end,
  })
elseif phase == "install" then
  assert(not dpp.load_state(base), "cannot load generated dpp state")
  vim.api.nvim_create_autocmd("User", {
    pattern = { "Dpp:ext:installer:updateDone", "Dpp:extActionPost:installer:install" },
    once = true,
    callback = function()
      finish("dpp plugins installed")
    end,
  })
  vim.api.nvim_create_autocmd("User", {
    pattern = "DenopsReady",
    once = true,
    callback = function()
      local missing = dpp.sync_ext_action("installer", "getNotInstalled") or {}
      print("dpp missing plugins: " .. #missing)
      if #missing == 0 then
        finish("all dpp plugins were already installed")
      else
        dpp.async_ext_action("installer", "install")
      end
    end,
  })
else
  error("unknown DPP_BUILD_PHASE: " .. phase)
end

vim.cmd("runtime plugin/denops.vim")
