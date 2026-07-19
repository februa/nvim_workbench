local M = {}
local capabilities = require("workbench.capabilities")

local function setup_colorscheme()
  require("wisteria").setup({
    style = "dark",
    transparent = true,
  })
  vim.cmd.colorscheme("wisteria")
end

local function setup_statusline()
  if capabilities.nerd_font then
    require("nvim-web-devicons").setup()
  end

  local component_separators = "|"
  local section_separators = { left = "", right = "" }
  local sections = {
    lualine_a = { "mode" },
    lualine_b = { "branch", "diff", "diagnostics" },
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "filetype", "encoding" },
    lualine_y = { "progress" },
    lualine_z = { "location" },
  }
  local inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = {},
    lualine_y = {},
    lualine_z = { "location" },
  }

  if capabilities.nerd_font then
    component_separators = ""
    section_separators = { left = "", right = "" }
    sections = {
      lualine_a = {
        { "mode", separator = { left = "" }, right_padding = 2 },
      },
      lualine_b = { "branch", "diff", "diagnostics" },
      lualine_c = {
        { "filename", path = 1 },
        "%=",
      },
      lualine_x = {},
      lualine_y = { "filetype", "encoding", "progress" },
      lualine_z = {
        { "location", separator = { right = "" }, left_padding = 2 },
      },
    }
    inactive_sections = {
      lualine_a = { { "filename", path = 1 } },
      lualine_b = {},
      lualine_c = {},
      lualine_x = {},
      lualine_y = {},
      lualine_z = { "location" },
    }
  end

  require("lualine").setup({
    options = {
      theme = "wisteria",
      icons_enabled = capabilities.nerd_font,
      component_separators = component_separators,
      section_separators = section_separators,
    },
    sections = sections,
    inactive_sections = inactive_sections,
  })

  vim.g.workbench_lualine_style = capabilities.nerd_font and "bubbles" or "plain"
end

local function setup_key_hints()
  local which_key = require("which-key")
  which_key.setup({
    preset = "helix",
    delay = 300,
    icons = {
      breadcrumb = ">",
      separator = "->",
      group = "+",
      mappings = capabilities.nerd_font,
      rules = capabilities.nerd_font and {} or false,
      colors = capabilities.nerd_font,
    },
  })
  which_key.add({
    { "s", group = "ddu/search" },
    { "<leader>", group = "leader" },
    { "<leader>r", group = "rename/run" },
    { "g", group = "navigation" },
  })
end

local function setup_markdown()
  local heading_icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " }
  local checkbox = {
    unchecked = { icon = "[ ] " },
    checked = { icon = "[x] " },
    custom = {
      todo = { raw = "[-]", rendered = "[-] ", highlight = "RenderMarkdownTodo" },
    },
  }
  local quote_icon = "|"

  if capabilities.nerd_font then
    heading_icons = { "󰒡 ", "󰒣 ", "󰒥 ", "󰒧 ", "󰒩 ", "󰒫 " }
    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked = { icon = "󰡒 " },
      custom = {
        todo = { raw = "[-]", rendered = "󰕔 ", highlight = "RenderMarkdownTodo" },
      },
    }
    quote_icon = "▋"
  end

  require("render-markdown").setup({
    file_types = { "markdown" },
    latex = { enabled = false },
    yaml = { enabled = false },
    heading = {
      sign = false,
      icons = heading_icons,
      position = "inline",
      width = "block",
    },
    code = {
      sign = false,
      language_icon = capabilities.nerd_font,
      border = "thin",
    },
    checkbox = checkbox,
    quote = { icon = quote_icon },
    sign = { enabled = false },
  })
end

function M.setup()
  setup_colorscheme()
  setup_statusline()
  setup_key_hints()
  setup_markdown()
end

return M
