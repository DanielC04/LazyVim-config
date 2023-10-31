-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- This file is automatically loaded by lazyvim.config.init
local Util = require("lazyvim.util")

-- set mapleader and localleader
vim.g.mapleader = " "
vim.g.maplocalleader = ","

local function map(mode, lhs, rhs, opts)
  local keys = require("lazy.core.handler").handlers.keys
  ---@cast keys LazyKeysHandler
  -- do not create the keymap if a lazy keys handler exists
  if not keys.active[keys.parse({ lhs, mode = mode }).id] then
    opts = opts or {}
    opts.silent = opts.silent ~= false
    if opts.remap and not vim.g.vscode then
      opts.remap = nil
    end
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

-- exit insert/Terminal mode quicker
map("i", "jk", "<escape>", { desc = "exit insert mode" })
map("v", "jk", "<escape>", { desc = "exit insert mode" })
map("t", "jk", "<escape>", { desc = "exit insert mode" })
map("t", "jk", "<C-\\><C-N>", { desc = "exit terminal mode" })
map("t", "jk<C-j>", "<cmd>ToggleTerm direction<cr>", { desc = "toggle terminal from terminal mode" })

-- make resizing windows smoother
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("t", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("t", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })

-- make switching out of terminal easier
map("t", "<leader>ww", "<escape><leader>ww")

-- toggle zenmode
map("n", "zn", "<cmd>ZenMode<cr>", { desc = "Toggle zenmode" })

-- latex: make rightarrow
vim.cmd("abb ra $\\rightarrow$")
-- latex: surround selection with mathmode
map("v", "<C-m>", "c$$<esc>hp", { desc = "surround selection with math-mode $" })
map("n", "<C-m>", "i$<esc>yllp", { desc = "surround char under cursor with math-mode $" })
map("i", "<C-m>", "$<esc>li$", { desc = "surround char under cursor with math-mode$" })

-- make clipboard work automatically with + register
-- vim.cmd.set("clipboard+=unnamedplus")
map("n", "<leader>y", '"*y')
map("v", "<leader>y", '"*y')
map("n", "<leader>p", '"*p')

-- insert emojis in insert mode
map("i", "<localleader>e", "<cmd>IconPickerInsert<cr>")

-- switch spell checked language
map("n", "<leader>spelld", "<cmd>set spell spelllang=de_de<cr>", { desc = "set spell checked language to german" })
map("n", "<leader>spelle", "<cmd>set spell spelllang=en_us<cr>", { desc = "set spell checked language to english" })

-- enable gf on links in obsidian
vim.keymap.set("n", "gf", function()
  if require("obsidian").util.cursor_on_markdown_link() then
    return "<cmd>ObsidianFollowLink<CR>"
  else
    return "gf"
  end
end, { noremap = false, expr = true })
