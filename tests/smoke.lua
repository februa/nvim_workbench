local function assert_executable(command)
  assert(vim.fn.executable(command) == 1, command .. " is not executable")
end

assert(vim.version().major == 0 and vim.version().minor == 12 and vim.version().patch == 4, "unexpected Neovim version")

for _, command in ipairs({
  "clangd",
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
  "gitsigns.nvim",
  "lazy.nvim",
  "nvim-lspconfig",
  "nvim-treesitter",
  "plenary.nvim",
  "telescope.nvim",
}) do
  local path = vim.fn.stdpath("data") .. "/lazy/" .. plugin
  assert(vim.uv.fs_stat(path), "missing plugin: " .. plugin)
end

for _, language in ipairs({ "bash", "c", "cpp", "json", "lua", "markdown", "python", "vim", "vimdoc", "yaml" }) do
  assert(pcall(vim.treesitter.language.add, language), "missing Tree-sitter parser: " .. language)
end

assert(vim.g.clipboard and vim.g.clipboard.name == "OSC 52", "OSC 52 clipboard provider is not active")
print("nvim-workbench smoke test: OK")
vim.cmd("qa")
