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
| `<leader>ga` | Generate Anki cards (`obsidian_to_anki/main.py`) |

Pasting images: pastify.nvim (`:Pastify`) saves to `/media/` and inserts `![](…)`.

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
| `begincard` / `turncard` / `endcard` | Anki card markers (deck `Uni::Semester1::Wirtschaft`) |

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
