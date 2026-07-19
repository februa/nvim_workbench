local M = {}
local capabilities = require("workbench.capabilities")

local function start(config)
  vim.fn["ddu#start"](config)
end

local function map_ui(buffer, mode, lhs, action, params)
  vim.keymap.set(mode, lhs, function()
    if params then
      vim.fn["ddu#ui#do_action"](action, params)
    else
      vim.fn["ddu#ui#do_action"](action)
    end
  end, { buffer = buffer, silent = true })
end

local function setup_ui_keymaps()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ddu-ff",
    callback = function(args)
      map_ui(args.buf, "n", "<CR>", "itemAction")
      map_ui(args.buf, "n", "<Space>", "toggleSelectItem")
      map_ui(args.buf, "n", "i", "openFilterWindow")
      map_ui(args.buf, "n", "p", "preview")
      map_ui(args.buf, "n", "q", "quit")
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ddu-ff-filter",
    callback = function(args)
      map_ui(args.buf, "i", "<CR>", "closeFilterWindow")
      map_ui(args.buf, { "i", "n" }, "<C-c>", "quit")
    end,
  })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "ddu-filer",
    callback = function(args)
      map_ui(args.buf, "n", "<CR>", "itemAction", { name = "open" })
      map_ui(args.buf, "n", "l", "expandItem", { mode = "toggle" })
      map_ui(args.buf, "n", "h", "itemAction", { name = "narrow", params = { path = ".." } })
      map_ui(args.buf, "n", "q", "quit")
    end,
  })
end

function M.setup()
  setup_ui_keymaps()

  vim.api.nvim_create_autocmd("User", {
    pattern = "DenopsReady",
    once = true,
    callback = function()
      vim.fn["ddu#custom#patch_global"]({
        ui = "ff",
        uiParams = {
          ff = {
            split = "horizontal",
            splitDirection = "botright",
            winHeight = 15,
            prompt = ">>> ",
            previewSplit = "vertical",
            autoAction = { name = "preview" },
            autoResize = true,
          },
        },
        sourceOptions = {
          _ = {
            matchers = { "matcher_substring" },
            ignoreCase = true,
            columns = { capabilities.nerd_font and "icon_filename" or "filename" },
          },
        },
        filterParams = {
          matcher_substring = { highlightMatched = "Search" },
        },
        kindOptions = {
          file = { defaultAction = "open" },
        },
      })
      vim.g.workbench_ddu_column = capabilities.nerd_font and "icon_filename" or "filename"
      vim.g.workbench_ddu_ready = true
    end,
  })

  local opts = { silent = true }
  vim.keymap.set("n", "sN", function()
    start({
      name = "files",
      sources = { { name = "file_rec", params = { path = vim.fn.expand("%:p:h") } } },
    })
  end, vim.tbl_extend("force", opts, { desc = "Find files from buffer directory" }))

  vim.keymap.set("n", "s;", function()
    start({ name = "buffers", sources = { { name = "buffer" } } })
  end, vim.tbl_extend("force", opts, { desc = "Find buffers" }))

  vim.keymap.set("n", "sm", function()
    start({
      name = "recent",
      sources = { { name = "buffer" }, { name = "file_old" } },
      uiParams = { ff = { displaySourceName = "short" } },
    })
  end, vim.tbl_extend("force", opts, { desc = "Find buffers and recent files" }))

  vim.keymap.set("n", "s/", function()
    start({ name = "lines", sources = { { name = "line" } } })
  end, vim.tbl_extend("force", opts, { desc = "Find lines" }))

  vim.keymap.set("n", "sg", function()
    vim.ui.input({ prompt = "grep: " }, function(pattern)
      if pattern and pattern ~= "" then
        start({ name = "grep", sources = { { name = "rg", params = { input = pattern } } } })
      end
    end)
  end, vim.tbl_extend("force", opts, { desc = "Search text" }))

  vim.keymap.set("n", "sn", function()
    start({
      name = "filer",
      ui = "filer",
      sources = { { name = "file" } },
      sourceOptions = { file = { path = vim.fn.expand("%:p:h") } },
      uiParams = {
        filer = {
          split = "horizontal",
          splitDirection = "botright",
          winHeight = 15,
          sortTreesFirst = true,
        },
      },
      actionOptions = { narrow = { quit = false } },
    })
  end, vim.tbl_extend("force", opts, { desc = "Open file browser" }))
end

return M
