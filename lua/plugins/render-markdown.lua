-- Render markdown in the buffer (headings, callouts like >[!Definition], tables, checkboxes, wikilinks).
-- obsidian.nvim's own UI is disabled (see obsidian.lua) so the two don't fight.
-- Toggle with <leader>um.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    code = { sign = false, width = "block", right_pad = 1 },
    heading = { sign = false },
    latex = { enabled = false }, -- keep $...$ math as source (needs an external converter otherwise)
  },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    Snacks.toggle({
      name = "Render Markdown",
      get = require("render-markdown").get,
      set = require("render-markdown").set,
    }):map("<leader>um")
  end,
}
