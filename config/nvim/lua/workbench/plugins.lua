local M = {}

function M.setup()
  require("workbench.display").setup()

  require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "bash", "c", "cpp", "json", "lua", "markdown", "python", "vim", "vimdoc", "yaml" },
    callback = function(args)
      pcall(vim.treesitter.start, args.buf)
    end,
  })

  require("conform").setup({
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "ruff_format" },
    },
    format_on_save = function(bufnr)
      local disabled = { c = true, cpp = true }
      if disabled[vim.bo[bufnr].filetype] then
        return nil
      end
      return { timeout_ms = 500, lsp_format = "fallback" }
    end,
  })

  vim.keymap.set({ "n", "v" }, "<leader>f", function()
    require("conform").format({ async = true, lsp_format = "fallback" })
  end, { desc = "Format buffer" })

  require("gitsigns").setup()
  require("nvim-autopairs").setup()
  require("nvim-surround").setup()
  require("fidget").setup({ notification = { override_vim_notify = false } })

  vim.keymap.set({ "n", "x" }, "*", "<Plug>(asterisk-z*)", { desc = "Search word forward" })
  vim.keymap.set({ "n", "x" }, "#", "<Plug>(asterisk-z#)", { desc = "Search word backward" })
  vim.keymap.set({ "n", "x" }, "g*", "<Plug>(asterisk-gz*)", { desc = "Search partial word forward" })
  vim.keymap.set({ "n", "x" }, "g#", "<Plug>(asterisk-gz#)", { desc = "Search partial word backward" })

  require("workbench.ddu").setup()
end

return M
