vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("workbench.options")
require("workbench.keymaps")
require("workbench.clipboard")

require("workbench.dpp")
require("workbench.plugins").setup()
require("workbench.lsp")
