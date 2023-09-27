return {
  {
    "akinsho/toggleterm.nvim",
    config = true,
    cmd = "ToggleTerm",
    keys = {
      { "<leader>kk", "<cmd>ToggleTerm direction<cr>", desc = "Toggle terminal in previously used orientation" },
      { "<leader>kkh", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Toggle horizontal terminal" },
      { "<leader>kkt", "<cmd>ToggleTerm direction=tab<cr>", desc = "Toggle terminal in new tab" },
      { "<leader>kkv", "<cmd>ToggleTerm direction=vertical size=40<cr>", desc = "Toggle vertical terminal" },
      { "<leader>kkf", "<cmd>ToggleTerm direction=float<cr>", desc = "Toggle floating terminal" },
    },
    opts = {
      open_mapping = [[<leader>kk]],
      direction = "horizontal",
      shade_filetypes = {},
      hide_numbers = true,
      shade_terminal = true,
      insert_mappings = true,
      terminal_mappings = true,
      start_in_insert = true,
      close_on_exit = true,
    },
  },
}
