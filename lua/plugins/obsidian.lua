return {
  "epwalsh/obsidian.nvim",
  lazy = true,
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
    dir = "/media/daniel/Documents/Obsidian/", -- no need to call 'vim.fn.expand' here
    mappings = {},
  },
  overwrite_mappings = true,
}
