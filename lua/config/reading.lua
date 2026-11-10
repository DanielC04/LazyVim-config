-- Reading notes (vault) -> reading list on dcermann.de, see reading_sync/ in the vault
local anki = require("config.anki")
local M = {}

M.script = anki.vault .. "/reading_sync/main.py"

local function run(args, title)
  anki.run(args, title, M.script)
end

function M.setup()
  vim.api.nvim_create_user_command("ReadingSync", function(o)
    run({ "sync", o.bang and "--push" or "--commit" }, o.bang and "Reading sync + push" or "Reading sync")
  end, { bang = true, desc = "Publish reading notes to dcermann.de and commit (! = also push/deploy)" })

  vim.api.nvim_create_user_command("ReadingImport", function()
    run({ "import" }, "Reading import")
  end, { desc = "Create vault notes for site reading-list entries that have none" })

  vim.api.nvim_create_user_command("ReadingLint", function()
    run({ "lint" }, "Reading lint")
  end, { desc = "Check all reading notes, results in quickfix" })

  vim.keymap.set("n", "<leader>oP", "<cmd>ReadingSync<cr>", { desc = "Reading: publish to website (commit)" })
end

return M
