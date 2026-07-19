local map = vim.keymap.set

map("n", "<Esc>", "<cmd>nohlsearch<CR>")
map("n", "<leader>w", "<cmd>write<CR>", { desc = "Write buffer" })
map("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Diagnostics list" })
map("n", "Y", "y$", { desc = "Yank to end of line" })
map("x", ">", ">gv", { desc = "Indent and keep selection" })
map("x", "<", "<gv", { desc = "Unindent and keep selection" })
map("i", "jj", "<Esc>", { desc = "Exit insert mode" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })
