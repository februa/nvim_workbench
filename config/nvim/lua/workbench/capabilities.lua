local M = {}

-- The terminal renders glyphs, so the container cannot reliably detect its
-- font. Keep the safe plain-text mode unless the launcher explicitly opts in.
M.nerd_font = vim.env.NVIM_NERD_FONT == "1"
vim.g.workbench_nerd_font = M.nerd_font

return M
