-- Live diagnostics for vault notes (needs only python3):
--   anki_cards   <!-- card ... --> markup        (obsidian_to_anki/main.py lint)
--   reading_meta reading-note properties          (reading_sync/main.py lint)
return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    local anki = require("config.anki")
    local reading = require("config.reading")

    local function in_vault(ctx)
      return ctx.filename:sub(1, #anki.vault + 1) == anki.vault .. "/"
    end

    local function linter(name, script, source)
      return {
        name = name,
        cmd = "python3",
        stdin = true,
        args = {
          script,
          "lint",
          "--stdin-name",
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        },
        stream = "stdout",
        ignore_exitcode = true,
        parser = require("lint.parser").from_errorformat(anki.efm, { source = source }),
        condition = in_vault, -- LazyVim extension: only lint notes inside the vault
      }
    end

    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters_by_ft.markdown = opts.linters_by_ft.markdown or {}
    vim.list_extend(opts.linters_by_ft.markdown, { "anki_cards", "reading_meta" })

    opts.linters = opts.linters or {}
    opts.linters.anki_cards = linter("anki_cards", anki.script, "anki")
    opts.linters.reading_meta = linter("reading_meta", reading.script, "reading")
  end,
}
