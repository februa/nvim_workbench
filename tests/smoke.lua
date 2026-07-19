local function assert_executable(command)
  assert(vim.fn.executable(command) == 1, command .. " is not executable")
end

assert(vim.version().major == 0 and vim.version().minor == 12 and vim.version().patch == 4, "unexpected Neovim version")

for _, command in ipairs({
  "clangd",
  "deno",
  "fd",
  "git",
  "lua-language-server",
  "node",
  "pyright-langserver",
  "rg",
  "ruff",
  "shellcheck",
  "stylua",
}) do
  assert_executable(command)
end

for _, plugin in ipairs({
  "conform.nvim",
  "ddu.vim",
  "ddu-ui-ff",
  "ddu-ui-filer",
  "ddu-column-icon_filename",
  "fidget.nvim",
  "gitsigns.nvim",
  "lualine.nvim",
  "nvim-lspconfig",
  "nvim-autopairs",
  "nvim-surround",
  "nvim-treesitter",
  "nvim-web-devicons",
  "render-markdown.nvim",
  "vim-asterisk",
  "vimdoc-ja",
  "which-key.nvim",
  "wisteria.nvim",
}) do
  local spec = vim.fn["dpp#get"](plugin)
  assert(type(spec) == "table" and spec.path, "missing dpp plugin: " .. plugin)
  assert(vim.uv.fs_stat(spec.path), "missing plugin path: " .. plugin)
end

assert(pcall(require, "fidget"), "fidget.nvim failed to load")
assert(pcall(require, "nvim-autopairs"), "nvim-autopairs failed to load")
assert(pcall(require, "nvim-surround"), "nvim-surround failed to load")
assert(pcall(require, "lualine"), "lualine.nvim failed to load")
assert(pcall(require, "which-key"), "which-key.nvim failed to load")
assert(pcall(require, "render-markdown"), "render-markdown.nvim failed to load")
assert(pcall(require, "nvim-web-devicons"), "nvim-web-devicons failed to load")
local nerd_font = vim.env.NVIM_NERD_FONT == "1"
assert(vim.g.workbench_nerd_font == nerd_font, "Nerd Font capability does not match the environment")
assert(not vim.o.relativenumber, "relative line numbers must remain disabled")
assert(vim.g.colors_name == "wisteria", "wisteria colorscheme is not active")
assert(vim.o.statusline:find("lualine", 1, true), "lualine statusline is not active")
local lualine_config = require("lualine").get_config()
assert(lualine_config.options.icons_enabled == nerd_font, "lualine icon mode is incorrect")
local expected_lualine_style = nerd_font and "bubbles" or "plain"
assert(vim.g.workbench_lualine_style == expected_lualine_style, "lualine style does not match Nerd Font mode")
if nerd_font then
  assert(lualine_config.options.section_separators.left == "", "missing left bubbles separator")
  assert(lualine_config.options.section_separators.right == "", "missing right bubbles separator")
else
  assert(lualine_config.options.component_separators.left == "|", "plain lualine separator is incorrect")
  assert(lualine_config.options.section_separators.left == "", "plain lualine must not use Nerd Font separators")
end
assert(vim.fn.exists(":RenderMarkdown") == 2, "RenderMarkdown command is missing")
assert(vim.fn.maparg("*", "n") ~= "", "vim-asterisk mapping is missing")
assert(#vim.api.nvim_get_runtime_file("doc/help.jax", false) > 0, "Japanese help is missing")
assert(vim.fn.exists(":DppInfo") == 2, "read-only :DppInfo command is missing")
for _, command in ipairs({ "DppInstall", "DppUpdate", "DppMakeState", "DppClearCache", "DppClean" }) do
  assert(vim.fn.exists(":" .. command) == 0, "runtime mutation command must not exist: " .. command)
end

for _, language in ipairs({ "bash", "c", "cpp", "json", "lua", "markdown", "python", "vim", "vimdoc", "yaml" }) do
  assert(pcall(vim.treesitter.language.add, language), "missing Tree-sitter parser: " .. language)
end

assert(vim.g.clipboard and vim.g.clipboard.name == "OSC 52", "OSC 52 clipboard provider is not active")
assert(vim.fn.filewritable(vim.fn.stdpath("state")) == 2, "Neovim state directory is not writable")
assert(vim.o.shada:find("'1000", 1, true), "ShaDa old-file retention is not set to 1000")

local finished = false
local current = 0
local transitioning = false
local action_started = false

vim.cmd.cd("/opt/workbench/tests/fixtures")

local probes = {
  {
    name = "workbench-smoke-ff",
    sources = {
      { name = "buffer" },
      { name = "file_old" },
      { name = "file_rec", params = { path = vim.fn.getcwd() } },
      { name = "line" },
      { name = "rg", params = { input = "__nvim_workbench_smoke_probe__" } },
    },
  },
  {
    name = "workbench-smoke-filer",
    ui = "filer",
    sources = { { name = "file" } },
    sourceOptions = { file = { path = vim.fn.getcwd() } },
  },
  {
    name = "workbench-smoke-file-action",
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
  assert(vim.fn["denops#plugin#is_loaded"]("ddu") == 1, "ddu denops plugin failed to load offline")
  local expected_column = nerd_font and "icon_filename" or "filename"
  assert(vim.g.workbench_ddu_column == expected_column, "ddu column does not match Nerd Font mode")
  finished = true
  print("nvim-workbench smoke test: OK")
  vim.cmd("qall!")
end

local function assert_ui_keymaps()
  for _, lhs in ipairs({ "q", "<CR>" }) do
    local mapping = vim.fn.maparg(lhs, "n", false, true)
    assert(type(mapping) == "table" and mapping.buffer == 1, "missing ddu UI mapping: " .. lhs)
  end
end

vim.api.nvim_create_autocmd("User", {
  pattern = "Ddu:uiReady",
  callback = function()
    vim.schedule(function()
      if finished or transitioning then
        return
      end

      assert_ui_keymaps()
      if current < #probes then
        transitioning = true
        vim.api.nvim_feedkeys("q", "xt", false)
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
        vim.api.nvim_feedkeys(vim.keycode("<CR>"), "xt", false)
        vim.defer_fn(function()
          assert(vim.bo.filetype ~= "ddu-ff", "Enter did not close the ddu UI")
          finish()
        end, 100)
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
    print("adopted ddu extensions timed out in offline smoke test")
    vim.cmd("cquit 1")
  end
end, 30000)
