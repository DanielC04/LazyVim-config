-- Obsidian -> Anki export, see obsidian_to_anki/ in the vault and CHEATSHEET.md
local M = {}

M.vault = "/documents/Notes"
M.script = M.vault .. "/obsidian_to_anki/main.py"
M.efm = "%f:%l:%c: %trror: %m,%f:%l:%c: %tarning: %m"

--- Run main.py with `args`, put its diagnostics into the quickfix list.
function M.run(args, title)
  vim.cmd("silent! wall") -- the exporter reads files from disk
  local cmd = vim.list_extend({ "uv", "run", "--quiet", "--script", M.script }, args)
  local cwd = vim.fn.getcwd() -- paths in the output are relative to this
  vim.notify(title .. " …", vim.log.levels.INFO, { title = "Anki" })
  vim.system(cmd, { text = true, cwd = cwd }, function(res)
    vim.schedule(function()
      local lines = vim.split((res.stdout or "") .. (res.stderr or ""), "\n", { trimempty = true })
      local items = vim.tbl_filter(function(item)
        return item.valid == 1
      end, vim.fn.getqflist({ lines = lines, efm = M.efm }).items)
      vim.fn.setqflist({}, " ", { title = title, items = items })
      vim.cmd("checktime") -- reload buffers that got new card ids

      local summary = vim.tbl_filter(function(l)
        return not l:match(":%d+:%d+: ")
      end, lines)
      local level = res.code == 0 and vim.log.levels.INFO
        or res.code == 1 and vim.log.levels.WARN
        or vim.log.levels.ERROR
      vim.notify(table.concat(summary, "\n"), level, { title = "Anki" })
      if #items > 0 then
        vim.cmd("copen")
      end
    end)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("AnkiSync", function(o)
    M.run(o.bang and { "sync", "--force" } or { "sync" }, "Anki sync")
  end, { bang = true, desc = "Export changed cards to Anki (! = all files)" })

  vim.api.nvim_create_user_command("AnkiSyncFile", function()
    M.run({ "sync", vim.api.nvim_buf_get_name(0) }, "Anki sync (file)")
  end, { desc = "Export cards of the current file to Anki" })

  vim.api.nvim_create_user_command("AnkiLint", function()
    M.run({ "lint" }, "Anki lint")
  end, { desc = "Check all cards in the vault, results in quickfix" })

  vim.keymap.set("n", "<leader>ga", "<cmd>AnkiSync<cr>", { desc = "Anki: export changed cards" })
  vim.keymap.set("n", "<leader>gA", "<cmd>AnkiSyncFile<cr>", { desc = "Anki: export cards of this file" })
end

return M
