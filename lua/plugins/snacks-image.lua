-- Inline images (incl. Obsidian ![[embeds]] from media/) and rendered LaTeX ($...$, $$...$$)
-- in markdown buffers. Needs a kitty-graphics terminal (kitty/ghostty/wezterm; NOT Ptyxis),
-- ImageMagick (`magick`) and pdflatex for math. Check with :checkhealth snacks
-- Formulas show as images in normal mode; move the cursor onto one to see the source.
return {
  "folke/snacks.nvim",
  opts = {
    image = {
      enabled = true,
      doc = {
        inline = true,
        max_width = 90,
        max_height = 30,
      },
      img_dirs = { "media", "img", "images", "assets", "attachments" },
      math = {
        enabled = true,
        latex = {
          font_size = "large",
          packages = { "amsmath", "amssymb", "amsfonts", "mathtools", "xcolor" },
        },
      },
    },
  },
  config = function(_, opts)
    require("snacks").setup(opts)
    -- Upstream bug (snacks 882c996): a placement closed before its image finished
    -- converting (e.g. re-attaching while paging/zooming the PDF reader) keeps its
    -- progress timer alive forever. It redraws "identify loading …" on line 0 and,
    -- by clearing the shared "snacks.image" namespace every 80ms, wipes the new
    -- placement's image. Same function, plus a stop on `self.closed`.
    local P = require("snacks.image.placement")
    local ns = vim.api.nvim_create_namespace("snacks.image")
    function P:progress()
      if self.opts.inline or self:ready() then
        return
      end
      vim.bo[self.buf].modifiable = true
      vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, {})
      vim.bo[self.buf].modifiable = false
      local timer = assert(vim.uv.new_timer())
      timer:start(
        0,
        80,
        vim.schedule_wrap(function()
          if self.closed or self:ready() or self.img:failed() or not vim.api.nvim_buf_is_valid(self.buf) then
            timer:stop()
            if not timer:is_closing() then
              timer:close()
            end
            return
          end
          vim.api.nvim_buf_clear_namespace(self.buf, ns, 0, -1)
          vim.api.nvim_buf_set_extmark(self.buf, ns, 0, 0, {
            virt_text = {
              { Snacks.util.spinner(), "SnacksImageSpinner" },
              { " " },
              { self.img._convert:current().name .. " loading …", "SnacksImageLoading" },
            },
          })
        end)
      )
    end
  end,
}
