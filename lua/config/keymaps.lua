-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- set mapleader and localleader
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- exit insert/visual mobe using jk instead of <escape>
vim.keymap.set("i", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("v", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("t", "jk", "<C-\\><C-N>", { desc = "exit insert mode" })

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

-- latex: make rightarrow
vim.cmd("abb ra $\\rightarrow$")

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

-- make switching tabs more comfortable on german keyboards
vim.keymap.set("n", "<leader><tab>$", "<cmd>tablast<cr>", { desc = "Last Tab" })
vim.keymap.set("n", "<leader><tab>0", "<cmd>tabfirst<cr>", { desc = "First Tab" })
vim.keymap.set("n", "<leader><tab><tab", "<cmd>tabnew<cr>", { desc = "Next Tab" })
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<leader><tab>l", "<cmd>tabnext<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>h", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

-- enable gf on links in obsidian
vim.keymap.set("n", "gf", function()
  if require("obsidian").util.cursor_on_markdown_link() then
    return "<cmd>ObsidianFollowLink<CR>"
  else
    return "gf"
  end
end, { noremap = false, expr = true })

-- Obsidian insert definition
vim.cmd("abb odef >[!Definition] <CR>>")
