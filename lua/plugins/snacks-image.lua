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
}
