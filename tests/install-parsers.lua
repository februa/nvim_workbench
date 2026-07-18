local parsers = { "bash", "c", "cpp", "json", "lua", "markdown", "markdown_inline", "python", "vim", "vimdoc", "yaml" }

local ok, treesitter = pcall(require, "nvim-treesitter")
assert(ok, "nvim-treesitter failed to load: " .. tostring(treesitter))
treesitter.setup({ install_dir = vim.fn.stdpath("data") .. "/site" })
treesitter.install(parsers):wait(600000)

for _, language in ipairs(parsers) do
  assert(pcall(vim.treesitter.language.add, language), "missing parser: " .. language)
end

vim.cmd("qa")
