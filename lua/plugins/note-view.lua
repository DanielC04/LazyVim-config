-- Ways to *read* a note instead of editing it:
--   <leader>ov  toggle reading mode in the current window (rendered, wrapped, no spell/numbers, zen)
--   <leader>oV  pick a vault note and open it in reading mode
--   <leader>og  fully rendered view with glow in a floating terminal (q closes)
--   <leader>oO  open the current note in the Obsidian app
--   <leader>H   open ~/.config/nvim/CHEATSHEET.md in a float (also :Cheatsheet)
local vault = "/documents/Notes"

local function cheatsheet()
  Snacks.win({
    file = vim.fn.stdpath("config") .. "/CHEATSHEET.md",
    width = 0.8,
    height = 0.9,
    border = "rounded",
    title = " Cheatsheet ",
    title_pos = "center",
    wo = { wrap = true, linebreak = true, spell = false, conceallevel = 2, number = false },
    bo = { filetype = "markdown" },
  })
end
vim.api.nvim_create_user_command("Cheatsheet", cheatsheet, { desc = "Open my config cheatsheet" })

local saved = {} -- window-local options to restore, keyed by window id

local function reading_on()
  require("render-markdown").set_buf(true)
  -- zen-mode opens a new float; style whichever window is current afterwards
  require("zen-mode").open({ window = { width = 100 } })
  local win = vim.api.nvim_get_current_win()
  local wo = vim.wo[win]
  saved[win] = {
    wrap = wo.wrap,
    linebreak = wo.linebreak,
    spell = wo.spell,
    number = wo.number,
    relativenumber = wo.relativenumber,
    signcolumn = wo.signcolumn,
    conceallevel = wo.conceallevel,
  }
  wo.wrap, wo.linebreak, wo.spell = true, true, false
  wo.number, wo.relativenumber, wo.signcolumn = false, false, "no"
  wo.conceallevel = 2
  vim.notify("Reading mode on", vim.log.levels.INFO, { title = "note-view" })
end

local function reading_off()
  local win = vim.api.nvim_get_current_win()
  for opt, val in pairs(saved[win] or {}) do
    vim.wo[win][opt] = val
  end
  saved[win] = nil
  if require("zen-mode.view").is_open() then
    require("zen-mode").close()
  end
  vim.notify("Reading mode off", vim.log.levels.INFO, { title = "note-view" })
end

local function toggle_reading()
  if require("zen-mode.view").is_open() or saved[vim.api.nvim_get_current_win()] then
    reading_off()
  else
    reading_on()
  end
end

local function pick_and_read()
  Snacks.picker.files({
    cwd = vault,
    ft = "md",
    title = "Read note",
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.cmd.edit(vim.fn.fnameescape(Snacks.picker.util.path(item)))
        vim.schedule(reading_on)
      end
    end,
  })
end

local function glow_view()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or not file:match("%.md$") then
    return vim.notify("Not a markdown file", vim.log.levels.WARN, { title = "note-view" })
  end
  Snacks.terminal({ "glow", "-p", "-w", "100", file }, {
    win = { style = "float", width = 0.8, height = 0.9, border = "rounded" },
    interactive = true,
  })
end

return {
  {
    "folke/zen-mode.nvim",
    keys = {
      { "<leader>ov", toggle_reading, desc = "Toggle reading mode" },
      { "<leader>oV", pick_and_read, desc = "Pick note to read" },
      { "<leader>og", glow_view, desc = "View note in glow (float)" },
      { "<leader>oO", "<cmd>Obsidian open<cr>", desc = "Open note in Obsidian app" },
      { "<leader>H", cheatsheet, desc = "Cheatsheet (my config)" },
    },
  },
}
