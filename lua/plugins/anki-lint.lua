-- Live diagnostics for Anki card markup (<!-- card ... -->) in vault notes.
-- Uses the linter of obsidian_to_anki/main.py; needs only python3.
return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    local anki = require("config.anki")
    opts.linters_by_ft = opts.linters_by_ft or {}
    opts.linters_by_ft.markdown = opts.linters_by_ft.markdown or {}
    table.insert(opts.linters_by_ft.markdown, "anki_cards")

    opts.linters = opts.linters or {}
    opts.linters.anki_cards = {
      name = "anki_cards",
      cmd = "python3",
      stdin = true,
      args = {
        anki.script,
        "lint",
        "--stdin-name",
        function()
          return vim.api.nvim_buf_get_name(0)
        end,
      },
      stream = "stdout",
      ignore_exitcode = true,
      parser = require("lint.parser").from_errorformat(anki.efm, { source = "anki" }),
      -- LazyVim extension: only lint notes inside the vault
      condition = function(ctx)
        return ctx.filename:sub(1, #anki.vault + 1) == anki.vault .. "/"
      end,
    }
  end,
}
