return {
  "epwalsh/obsidian.nvim",
  lazy = true,
  log_level = vim.log.levels.DEBUG,
  event = {
    -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    "BufReadPre /media/daniel/Documents/Obsidian/**.md",
    "BufNewFile /media/daniel/Documents/Obsidian/**.md",
  },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",

    -- see below for full list of optional dependencies 👇
  },
  opts = {
    dir = "/documents/Notes", -- no need to call 'vim.fn.expand' here
    mappings = {},
    daily_notes = {
      -- Optional, if you keep daily notes in a separate directory.
      folder = "dailies",
      -- Optional, if you want to change the date format for the ID of daily notes.
      date_format = "%d-%m-%Y",
      -- Optional, if you want to change the date format of the default alias of daily notes.
      alias_format = "%A,  %d %B %Y",
      -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
      template = "daily-note.md",
    },
    overwrite_mappings = true,
    templates = {
      subdir = "templates/",
      date_format = "%Y-%m-%d-%a",
      time_format = "%H:%M",
      substitutions = {
        writtendate = function()
          return os.date("%A, %d. %B %Y")
        end,
        yesterday = function()
          return os.date("%Y-%m-%d", os.time() - 86400)
        end,
      },
    },
  },
}
