-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
--
-- automatically format rust code on save
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.rs" },
  command = "!/home/daniel/.cargo/bin/rustfmt %",
})
