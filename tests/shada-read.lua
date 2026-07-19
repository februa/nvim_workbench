local expected = "/opt/workbench/tests/fixtures/sample.lua"

assert(vim.tbl_contains(vim.v.oldfiles, expected), "persisted file is missing from v:oldfiles")
print("nvim-workbench ShaDa persistence test: OK")
vim.cmd("qall!")
