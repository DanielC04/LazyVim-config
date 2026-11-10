# My Neovim cheatsheet

Open anywhere: `<leader>H` (or `:Cheatsheet`). `q` closes. Edit this file to keep it current:
`~/.config/nvim/CHEATSHEET.md` (config is a symlink to `~/LazyVim-config`, a git repo).

`<leader>` = **Space**. Localleader = **`\`** (init.lua sets `;`, lazy.lua sets `,`, but LazyVim's
defaults override both; vimtex mappings use `\`). Press `<leader>` and wait for which-key to list
everything, or `<leader>?` for buffer-local keys.

---

## Reading notes (images + LaTeX)

| Key | Does | File |
|---|---|---|
| `<leader>ov` | Toggle reading mode: zen, wrap, no spell/numbers, rendered markdown | `plugins/note-view.lua` |
| `<leader>oV` | Pick a vault note → open in reading mode | `plugins/note-view.lua` |
| `<leader>og` | Note in `glow` (floating terminal; text only, no images/math) | `plugins/note-view.lua` |
| `<leader>oO` | Open current note in the Obsidian app | `plugins/note-view.lua` |
| `<leader>um` | Toggle render-markdown (headings, callouts, tables, checkboxes) | `plugins/render-markdown.lua` |

**Images & formulas inline** (`plugins/snacks-image.lua`, snacks.image):
- `![[Pasted image ….png]]` / `![](…)` resolve from `media/`; `$…$` / `$$…$$` render as images.
- Cursor on a formula shows its source.
- **Only in kitty** (or ghostty/wezterm). Not in Ptyxis.
- Needs: `sudo dnf install kitty texlive-scheme-basic texlive-standalone texlive-preview
  texlive-varwidth texlive-mathtools texlive-amsfonts texlive-xcolor`
- Broken? `:checkhealth snacks`
- Paths with spaces need angle brackets: `![](<media/my image.png>)`, else not parsed as image.
- Image on the very last line of a file may not render: leave an empty line after it.

## Obsidian vault (`/documents/Notes`), `plugins/obsidian.lua`

| Key | Does |
|---|---|
| `<leader>oo` | Quick switch note |
| `<leader>on` | New note (template: `templates/obsidian-note.md`, file name = title) |
| `<leader>os` | Search vault |
| `<leader>ob` / `<leader>ol` | Backlinks / links in note |
| `<leader>ot` | Tags |
| `<leader>od` | Today's daily note (`dailies/`, `dd-mm-yyyy`) |
| `<leader>or` | Rename note (updates links) |
| `<leader>oT` | Insert template |
| `<leader>ol` (visual) | Link selection to note |
| `<leader>ox` (visual) | Extract selection to new note |
| `gf` / `<CR>` | Follow `[[link]]` (`<CR>` also toggles checkboxes) |
| `[[` + 2 chars | Link completion |
| `<leader>ga` / `<leader>gA` | Export Anki cards: changed files / current file (see below) |

Pasting images: pastify.nvim (`:Pastify`) saves to `/media/` and inserts `![](…)`.

## Anki cards from notes, `config/anki.lua` + `plugins/anki-lint.lua`

Exporter lives in the vault: `/documents/Notes/obsidian_to_anki/` (Python, run via `uv`).
**Anki must be running with the AnkiConnect add-on** (code `2055492159`) for sync, not for lint.

```markdown
<!-- card type="Basic" deck="Uni::Semester5::PEM" tags="uni, pem" -->
Front: markdown, $math$, $$display math$$, ![](<media/x y.png>), ![[img.png|300]], [[links]]
<!-- back -->
Back side
<!-- card -->
```

- Attributes: `type` (default `Basic`; also `Cloze`, `Basic (and reversed card)`, … any note
  type in Anki, case-insensitive), `deck` (default `Default`, created if missing), `tags`
  (comma-separated, spaces become `_`, tag `study` always added), `id` (written by sync, **don't
  edit or copy it**; a copied card with the same id is blocked).
- Cloze: deletions `{{c1::…}}` (or escaped `\{\{c1::…\}\}`) must be **before** `<!-- back -->`;
  the back goes into "Back Extra".
- Markers inside code blocks / inline code are ignored. Cards can be in subfolders too.
- Images are uploaded to Anki's media folder automatically (only those the cards use).

| Key / command | Does |
|---|---|
| `<leader>ga` / `:AnkiSync` | Save all, export cards of **changed** files, ids written back, buffers reloaded |
| `:AnkiSync!` | Same, but every file (after config/render changes) |
| `<leader>gA` / `:AnkiSyncFile` | Export cards of the current file (always, ignores cache) |
| `:AnkiLint` | Check every card in the vault → quickfix list |

- Errors/warnings land in the **quickfix list** (opens automatically; `]q`/`[q` to jump), summary
  as a notification. Live lint diagnostics (source `anki`) show in any vault note on
  open/save/InsertLeave: unclosed/stray tags, broken attributes, bad deck, wrong-case or unknown
  type, Cloze without deletion, empty front, missing image, unbalanced `$`, duplicate ids/fronts.
- Cards with errors are skipped; their file is retried on every sync until fixed. A file only
  counts as done (cache `obsidian_to_anki/.sync_state.json`, not in git) when all its cards worked.
- Existing notes are updated in place (review history kept), moved if the deck changed, and
  left alone if nothing changed. Tags `leech`/`marked` set in Anki are kept. Note type can't be
  changed by sync (error tells you what to do).
- Card without id whose front already exists in Anki (ids lost by the old exporter) gets
  relinked to that note instead of creating a duplicate.
- Deleting a card in the note does **not** delete it in Anki (do that in Anki).
- An update doesn't apply while the note is open in Anki's Browse window: close it, sync again.
- Shell: `cd /documents/Notes && obsidian_to_anki/main.py [sync] [-f] [-n] [FILES…]`
  (`-n` dry run, no Anki needed), `python3 obsidian_to_anki/main.py lint [FILES…]`.
  Exit code 0 ok, 1 card errors, 2 Anki not reachable.
- Settings (ignored folders, blacklisted files, known note types, AnkiConnect URL):
  `obsidian_to_anki/config.py`.

## Insert-mode abbreviations & shortcuts, `config/keymaps.lua`

| Type | Get |
|---|---|
| `jk` | Escape (insert, visual, **terminal**) |
| `mm<Space>` | `$\|$` inline math |
| `dmm<Space>` | `$$ \| $$` display math |
| `kl<Space>` | `{\|}` |
| `sl<Space>` / `dsl<Space>` | `\` / `\\` |
| `nl<Space>` | `\\` + newline |
| `yy` / `YY` | `<` / `>` (60% keyboard) |
| `lll` / `hhh` | Cursor one right / left |
| `reals` | `\mathbb{R}` |
| `odef` | `>[!Definition]` callout |
| `begincard` / `turncard` / `endcard` | Anki card markers (deck `Uni::Semester1::Wirtschaft`, edit after) |

Watch out: `yy` in insert mode means you can't type "yy".

## Normal-mode keys, `config/keymaps.lua`

| Key | Does |
|---|---|
| `<C-b>` | Wrap word in `**bold**` |
| `<leader>t` | Terminal fullscreen in a new tab (in a terminal: vsplit another). `gt`/`gT` switch tabs |
| `<C-Up>` | Grow window (normal + terminal) |
| `<leader>spe` / `spd` / `sps` | Spell language English / German / Spanish (spell is off by default) |
| `<leader>sv` | Source current lua file |
| `<leader>kk` | Toggle terminal (`kkh` horizontal, `kkv` vertical, `kkt` tab, `kkf` float) |

Mouse is disabled (`set mouse=`).

## Claude in Neovim, LazyVim extra `ai.claudecode` (claudecode.nvim)

| Key | Does |
|---|---|
| `<leader>ac` | Toggle Claude terminal (same session each time) |
| `<leader>af` | Focus Claude window |
| `<leader>wm` | Zoom current window fullscreen / back (LazyVim, any window; use on Claude after `<leader>af`) |
| `<leader>as` (visual) | Send selection to Claude |
| `<leader>ab` | Add current note as context |
| `<leader>aa` / `<leader>ad` | Accept / reject Claude's proposed edit (diff) |
| `<leader>ar` / `<leader>aC` | Resume old session / continue last one |

Claude started outside Neovim: type `/ide` in it to connect.

## LaTeX, `plugins/vimtex.lua`

- vimtex with **zathura** viewer, conceal on in `.tex`/`.bib`, `K` left to LSP hover.
- `\ll` compile, `\lv` view, `\lc` clean (vimtex defaults, localleader `\`).
- LazyVim extra `lang.tex` also active.

## Other plugins & setup

- **LazyVim extras** (`lazyvim.json`): dap.core, ai.copilot, ai.claudecode, lang clangd/python/rust/tex/typescript/json, vscode, ui.mini-starter.
- **DAP for C** (`config/dap-config.lua`): gdb, asks for the executable path.
- **Python host**: `~/.venv/bin/python3` (`config/options.lua`).
- **icon-picker.nvim**: `:IconPickerNormal` / `:IconPickerInsert`.
- **zen-mode**: `:ZenMode`.
- **nvim-markdown**: markdown syntax with math enabled.
- **`plugins/example.lua` is live** (LazyVim's sample): gruvbox installed, symbols-outline
  `<leader>cs`, `<leader>fp` find plugin file, telescope layout tweaks. Delete or trim it if unwanted.

## Claude Code (not Neovim)

- `/view [note]` and `/obsidian [note]` with a note pane: dev mod `note-view` in
  `~/.claude/dev-mods/…/note-view/`, only loaded in the session that built it.
