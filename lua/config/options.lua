-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
-- jkoopts.rocks.hererocks = false

-- Dedicated venv so system Python upgrades don't strand pynvim in a stale ~/.venv
vim.g.python3_host_prog = vim.fn.expand("~/.local/share/nvim/py-venv/bin/python3")
