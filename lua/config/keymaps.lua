-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--
--

-- set mapleader and localleader
vim.g.mapleader = " "

-- source neovim config to avoid having to restart neovim everytime I change somehting
vim.keymap.set("n", "<leader>sv", "<cmd>luafile %<cr>", { desc = "source neovim config" })

-- open terminal fullscreen (in its own tab)
vim.keymap.set("n", "<leader>t", function()
  if vim.bo.buftype ~= "terminal" then
    vim.cmd("tabnew")
    vim.cmd("terminal")
  else
    vim.cmd("vsplit")
    vim.cmd("terminal")
  end
  vim.cmd("startinsert")
end, { desc = "open terminal fullscreen" })

-- exit insert/visual mobe using jk instead of <escape>
vim.keymap.set("i", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("v", "jk", "<escape>", { desc = "exit insert mode" })
vim.keymap.set("t", "jk", "<C-\\><C-N>", { desc = "exit insert mode" })

-- Claude terminal: <C-k> / <C-j> scroll up / down (PageUp / PageDown),
-- <M-h> / <M-j> / <M-k> / <M-l> send the arrow keys left / down / up / right.
-- Buffer-local, set on TermEnter so it overrides snacks' <C-j>/<C-k> window-nav maps
-- (up/down nav is useless in the vertical Claude split; <C-h>/<C-l> nav still works).
vim.api.nvim_create_autocmd("TermEnter", {
  group = vim.api.nvim_create_augroup("claude_scroll_keys", { clear = true }),
  callback = function(ev)
    if not vim.api.nvim_buf_get_name(ev.buf):lower():find("claude", 1, true) then
      return
    end
    vim.keymap.set("t", "<C-k>", "<PageUp>", { buffer = ev.buf, desc = "Claude: scroll up" })
    vim.keymap.set("t", "<C-j>", "<PageDown>", { buffer = ev.buf, desc = "Claude: scroll down" })
    vim.keymap.set("t", "<M-h>", "<Left>", { buffer = ev.buf, desc = "Claude: cursor left" })
    vim.keymap.set("t", "<M-l>", "<Right>", { buffer = ev.buf, desc = "Claude: cursor right" })
    vim.keymap.set("t", "<M-j>", "<Down>", { buffer = ev.buf, desc = "Claude: arrow down" })
    vim.keymap.set("t", "<M-k>", "<Up>", { buffer = ev.buf, desc = "Claude: arrow up" })
  end,
})

-- make resizing windows smoother
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("t", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
vim.keymap.set("t", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })

-- markdown stuff
vim.keymap.set("n", "<C-B>", "i**<escape>2wi**<escape>", { desc = "Decrease window height" })

-- switch spell checked language
vim.keymap.set(
  "n",
  "<leader>spd",
  "<cmd>set spell spelllang=de_de<cr>",
  { desc = "set spell checked language to german" }
)
vim.keymap.set(
  "n",
  "<leader>sps",
  "<cmd>set spell spelllang=es<cr>",
  { desc = "set spell checked language to argentine spanish" }
)
vim.keymap.set(
  "n",
  "<leader>spe",
  "<cmd>set spell spelllang=en_us<cr>",
  { desc = "set spell checked language to english" }
)
-- default language: english
vim.cmd("set spell spelllang=en_us | setlocal nospell ")

-- latex: insert real number symbol
vim.cmd("abb reals \\mathbb{R}")

-- Obsidian insert definition
vim.cmd("abb odef >[!Definition] <CR>>")
-- Obsidian follow link (gf / <CR>): now set buffer-locally in lua/plugins/obsidian.lua
-- Obsidian -> Anki: :AnkiSync[!], :AnkiSyncFile, :AnkiLint, <leader>ga / <leader>gA
require("config.anki").setup()
-- Reading notes -> dcermann.de: :ReadingSync[!], :ReadingImport, :ReadingLint, <leader>oP
require("config.reading").setup()

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
