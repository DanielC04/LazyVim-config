return {
  "epwalsh/obsidian.nvim",
  version = "*", -- recommended, use latest release instead of latest commit
  lazy = true,
  event = {
    -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    "BufReadPre /documents/Notes/**.md",
    "BufNewFile /documents/Notes/**.md",
  },
  dependencies = {
    -- Required.
    "nvim-lua/plenary.nvim",
  },
  daily_notes = {
    -- Optional, if you keep daily notes in a separate directory.
    folder = "dailies",
    -- Optional, if you want to change the date format for the ID of daily notes.
    date_format = "%d-%m-%Y",
    -- Optional, if you want to change the date format of the default alias of daily notes.
    alias_format = "%A, %d %B %Y",
    -- Optional, if you want to automatically insert a template from your template directory like 'daily.md'
    template = "daily-note.md",
  },
  opts = {
    workspaces = {
      {
        name = "personal",
        path = "~/vaults/personal",
      },
      {
        name = "work",
        path = "~/vaults/work",
      },
    },
  },
}
