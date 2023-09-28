return {
  {
    "glepnir/template.nvim",
    cmd = { "Template", "TemProject" },
    config = function()
      require("template").setup({
        temp_dir = "/home/daniel/.config/nvim/templates/",
        author = "Daniel Cermann",
        email = "daniel.cermann@gmx.de",
      })
    end,
  },
}
