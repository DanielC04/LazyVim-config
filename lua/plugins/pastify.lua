return {
  "https://github.com/TobinPalmer/pastify.nvim",
  config = function()
    require("pastify").setup({
      opts = {
        absolute_path = false, -- use absolute or relative path to the working directory
        apikey = "", -- Api key, required for online saving
        local_path = "/media/", -- The path to put local files in, ex ~/Projects/<name>/assets/images/<imgname>.png
        save = "local", -- Either 'local' or 'online'
      },
      ft = { -- Custom snippets for different filetypes, will replace $IMG$ with the image url
        html = '<img src="$IMG$" alt="">',
        markdown = "![]($IMG$)",
        tex = [[\includegraphics[width=\linewidth]{$IMG$}]],
      },
    })
  end,
  event = "BufRead",
  lazy = true,
  --   require("clipboard-image").setup({
  --     -- Default configuration for all filetype
  --     default = {
  --       img_dir = "images",
  --       img_name = function()
  --         return os.date("%Y-%m-%d-%H-%M-%S")
  --       end, -- Example result: "2021-04-13-10-04-18"
  --       affix = "<\n  %s\n>", -- Multi lines affix
  --     },
  --     -- You can create configuration for ceartain filetype by creating another field (markdown, in this case)
  --     -- If you're uncertain what to name your field to, you can run `lua print(vim.bo.filetype)`
  --     -- Missing options from `markdown` field will be replaced by options from `default` field
  --     markdown = {
  --       img_dir = { "src", "assets", "img" }, -- Use table for nested dir (New feature form PR #20)
  --       img_dir_txt = "/media",
  --       img_handler = function(img) -- New feature from PR #22
  --         local script = string.format('./image_compressor.sh "%s"', img.path)
  --         os.execute(script)
  --       end,
  --     },
  --   })
  -- end,
}
