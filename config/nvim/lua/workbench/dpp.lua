local M = {}

M.base = vim.fn.stdpath("data") .. "/dpp"
M.repos = M.base .. "/repos/github.com"

local dpp_src = M.repos .. "/Shougo/dpp.vim"
local denops_src = M.repos .. "/vim-denops/denops.vim"

if not vim.uv.fs_stat(dpp_src) or not vim.uv.fs_stat(denops_src) then
  error("frozen dpp core is missing; rebuild the image")
end

vim.opt.runtimepath:prepend(dpp_src)
vim.opt.runtimepath:prepend(denops_src)

local dpp = require("dpp")
if dpp.load_state(M.base) then
  error("frozen dpp state is missing or invalid; rebuild the image")
end

vim.api.nvim_create_user_command("DppInfo", function()
  local plugins = vim.fn["dpp#get"]()
  local status_ok, denops_status = pcall(vim.fn["denops#server#status"])
  denops_status = status_ok and denops_status or "unavailable"
  vim.notify(
    table.concat({
      "dpp base: " .. M.base,
      "managed plugins: " .. vim.tbl_count(plugins),
      "Deno: " .. vim.fn.system({ "deno", "--version" }):match("deno [^\n]+"),
      "Denops: " .. tostring(denops_status),
      "Nerd Font icons: " .. (require("workbench.capabilities").nerd_font and "enabled" or "disabled"),
      "updates: rebuild the candidate image; runtime mutation is disabled",
    }, "\n"),
    vim.log.levels.INFO,
    { title = "Frozen dpp" }
  )
end, { desc = "Show frozen dpp state information" })

return M
