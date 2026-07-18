vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("workbench.options")
require("workbench.keymaps")
require("workbench.clipboard")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  error("lazy.nvim is missing from the frozen image; rebuild instead of downloading at runtime")
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup(require("workbench.plugins"), {
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  checker = { enabled = false },
  change_detection = { enabled = false },
  install = { missing = vim.env.NVIM_IMAGE_BUILD == "1" },
  rocks = { enabled = false },
  performance = { rtp = { reset = true } },
})

require("workbench.lsp")
