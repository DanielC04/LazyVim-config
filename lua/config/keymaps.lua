-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
--

-- This file is automatically loaded by lazyvim.config.init
local Util = require("lazyvim.util")

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
map("t", "jk", "<C-\\><C-N>", { desc = "exit terminal mode" })

-- make resizing windows smoother
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("t", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("t", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })

-- toggle zenmode
map("n", "zn", "<cmd>ZenMode<cr>", { desc = "Toggle zenmode" })
