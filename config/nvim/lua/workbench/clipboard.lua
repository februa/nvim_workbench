if vim.env.NVIM_CONTAINER ~= "1" then
  return
end

-- The provider below is explicit, so Neovim's built-in OSC 52 auto-detection is
-- redundant. Its XTGETTCAP `Ms` query is rendered as visible `+q4D73` text by
-- terminals that do not consume unknown DCS sequences (notably Prompt 3 over SSH).
local termfeatures = vim.g.termfeatures or {}
termfeatures.osc52 = false
vim.g.termfeatures = termfeatures

local osc52 = require("vim.ui.clipboard.osc52")

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = osc52.copy("+"),
    ["*"] = osc52.copy("*"),
  },
  paste = {
    ["+"] = osc52.paste("+"),
    ["*"] = osc52.paste("*"),
  },
}
