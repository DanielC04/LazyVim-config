-- Use telescope (not LazyVim's default picker, fzf-lua) for <leader>sg and <leader>sw.
return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      { "<leader>sg", false },
      { "<leader>sw", false, mode = { "n", "x" } },
    },
  },
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>sg",
        function()
          require("telescope.builtin").live_grep({ cwd = LazyVim.root() })
        end,
        desc = "Grep (Telescope, root dir)",
      },
      {
        "<leader>sw",
        function()
          require("telescope.builtin").grep_string({ cwd = LazyVim.root() })
        end,
        desc = "Word under cursor (Telescope, root dir)",
      },
      {
        "<leader>sw",
        function()
          local text = table.concat(vim.fn.getregion(vim.fn.getpos("v"), vim.fn.getpos(".")), "\n")
          require("telescope.builtin").grep_string({ cwd = LazyVim.root(), search = text })
        end,
        mode = "x",
        desc = "Selection (Telescope, root dir)",
      },
    },
  },
}
