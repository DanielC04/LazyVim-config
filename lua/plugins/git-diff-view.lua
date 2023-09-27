return {
  {
    "sindrets/diffview.nvim",
    config = function()
      require("diffview").setup({})
    end,
    keys = {
      {
        "<leader>gd",
        "<cmd>DiffviewOpen<cr>",
        desc = "open diff view for git",
      },
    },
  },
}
