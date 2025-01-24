-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--

-- set mapleader and localleader
vim.g.mapleader = " "

-- source neovim config to avoid having to restart neovim everytime I change somehting
vim.keymap.set("n", "<leader>sv", "<cmd>luafile %<cr>", { desc = "source neovim config" })

-- open terminal in bottom buffer
vim.keymap.set("n", "<leader>t", function()
  if vim.bo.buftype ~= "terminal" then
    vim.cmd("bo terminal")
    vim.cmd("horizontal resize 10")
  else
    vim.cmd("vsplit")
    vim.cmd("terminal")
  end
  vim.cmd("startinsert")
end, { desc = "open terminal at bottom" })

-- exit insert/visual mobe using jk instead of <escape>
vim.keymap.set("i", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("v", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("t", "jk", "<C-\\><C-N>", { desc = "exit insert mode" })

-- make resizing windows smoother
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("t", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("t", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })

-- switch spell checked language
vim.keymap.set(
  "n",
  "<leader>spd",
  "<cmd>set spell spelllang=de_de<cr>",
  { desc = "set spell checked language to german" }
)
vim.keymap.set(
  "n",
  "<leader>spe",
  "<cmd>set spell spelllang=en_us<cr>",
  { desc = "set spell checked language to english" }
)
-- default language: german
vim.cmd("set spell spelllang=de_de | setlocal nospell ")

-- latex: insert real number symbol
vim.cmd("abb reals \\mathbb{R}")

-- Obsidian insert definition
vim.cmd("abb odef >[!Definition] <CR>>")
-- Obsidian follow link
vim.keymap.set("n", "gf", function()
  if require("obsidian").util.cursor_on_markdown_link() then
    return "<cmd>ObsidianFollowLink<CR>"
  else
    return "gf"
  end
end, { noremap = false, expr = true })
-- Obsidian: generate learning cards
vim.keymap.set(
  "n",
  "<leader>ga",
  "<cmd>!python3 /documents/Notes/obsidian_to_anki/main.py<cr>",
  { desc = "generate ani keycards from obsidian notes" }
)

-- disable mouse
vim.cmd("set mouse=")

-- template to create a node
vim.cmd('abb begincard <!-- card type="Basic" deck="Uni::Semester1::Wirtschaft" tags="uni" -->')
vim.cmd("abb endcard <!-- card -->")
vim.cmd("abb turncard <!-- back -->")

-- my latex keymaps
vim.keymap.set("i", "mm<leader>", "$$<escape>i", { desc = "insert math mode" })
vim.keymap.set("i", "dmm<leader>", "$$  $$<escape>hhi", { desc = "insert math mode" })
vim.keymap.set("i", "nl<leader>", "\\\\<cr>", { desc = "insert new line" })
vim.keymap.set("i", "sl<leader>", "\\", { desc = "insert slash" })
vim.keymap.set("i", "dsl<leader>", "\\\\", { desc = "insert slash" })
vim.keymap.set("i", "kl<leader>", "{}<escape>i", { desc = "insert curly braces" })
vim.keymap.set("i", "lll", "<escape>la", { desc = "move cursor one to the right" })
vim.keymap.set("i", "hhh", "<escape>ha", { desc = "move cursor one to the left" })
vim.keymap.set("i", "yy", "<", { desc = "insert smaller than sign" })
vim.keymap.set("i", "YY", ">", { desc = "insert bigger than sign" })
