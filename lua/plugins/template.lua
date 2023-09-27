return {
  {
    "glepnir/template.nvim",
    cmd = { "Template", "TemProject" },
    config = function()
      require("template").setup({
        temp_dir = "~/.config/nvim/templates",
        author = "Daniel Cermann",
        email = "daniel.cermann@gmx.de",
      })

      require("telescope").load_extension("find_template")
    end,
  },
}
