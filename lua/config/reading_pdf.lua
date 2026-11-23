-- Read a paper's PDF next to its reading note: PDF pages on the left (rendered
-- with pdftoppm, shown with snacks.image in kitty), the note on the right.
-- Remarks go into the note tagged with their page (`- p.4: …`), and `p.N`
-- references in the note jump the PDF back to that page.
--
-- Which PDF: the note's frontmatter `pdf:` (local path, vault-relative path or
-- URL) wins; otherwise `url:` is used — arxiv abs/pdf links are turned into
-- PDF links, other URLs are tried and kept only if they really return a PDF.
-- Downloads are cached in ~/.cache/reading-pdfs.
--
-- Commands / keys
--   :ReadingPdf [path|url]   <leader>op   open the PDF for the current note
--   PDF pane:  ]p [p  <PageDown> <PageUp>  next / prev page
--              gp  go to page     t  toggle image / text view
--              r   remark at this page (jumps to the note)
--              Q   (visual, text view) quote selection into the note
--              q   close the PDF pane
--   Note:      ,r  remark at the current page    ,g  jump PDF to p.N under cursor
--              ,n / ,p  next / prev page

local M = {}

local cache = vim.fn.stdpath("cache") .. "/reading-pdfs"
local DPI = 150
local UA = "Mozilla/5.0 (X11; Linux x86_64) reading-pdf"

---@class ReadingPdfSession
---@field pdf string
---@field pages integer
---@field page integer
---@field mode "image"|"text"
---@field note_buf integer
---@field pdf_buf integer
---@field pdf_win integer
local S = nil ---@type ReadingPdfSession?

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Reading PDF" })
end

-- ── Finding the PDF ──────────────────────────────────────────────────────

local function frontmatter(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 200, false)
  local fm = {}
  if lines[1] ~= "---" then
    return fm
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      break
    end
    local k, v = lines[i]:match("^([%w_]+):%s*(.-)%s*$")
    if k and v ~= "" then
      fm[k] = v:gsub('^["\']', ""):gsub('["\']$', "")
    end
  end
  return fm
end

local function arxiv_id(url)
  local id = url:match("arxiv%.org/abs/([^%s?#]+)") or url:match("arxiv%.org/pdf/([^%s?#]+)")
  return id and id:gsub("%.pdf$", ""):gsub("/$", "")
end

--- Returns { path = local file } or { url = …, name = cache file name }, or nil + reason.
local function resolve(src, note_buf)
  if not src or src == "" then
    local fm = frontmatter(note_buf)
    src = fm.pdf or fm.url
    if not src then
      return nil, "note has no `pdf:` or `url:` in its frontmatter"
    end
  end
  if not src:match("^https?://") then
    local candidates = { vim.fn.expand(src) }
    local dir = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(note_buf), ":h")
    table.insert(candidates, dir .. "/" .. src)
    table.insert(candidates, require("config.anki").vault .. "/" .. src)
    for _, p in ipairs(candidates) do
      if vim.fn.filereadable(p) == 1 then
        return { path = vim.fn.fnamemodify(p, ":p") }
      end
    end
    return nil, "file not found: " .. src
  end
  local id = arxiv_id(src)
  if id then
    return { url = "https://arxiv.org/pdf/" .. id, name = "arxiv-" .. id:gsub("/", "_") .. ".pdf" }
  end
  local name = src:gsub("^https?://", ""):gsub("[^%w%.%-]", "_"):sub(1, 120)
  return { url = src, name = name:match("%.pdf$") and name or name .. ".pdf" }
end

local function is_pdf(path)
  local f = io.open(path, "rb")
  if not f then
    return false
  end
  local head = f:read(5)
  f:close()
  return head == "%PDF-"
end

local function fetch(target, cb)
  if target.path then
    return cb(target.path)
  end
  vim.fn.mkdir(cache, "p")
  local out = cache .. "/" .. target.name
  if vim.fn.filereadable(out) == 1 and is_pdf(out) then
    return cb(out)
  end
  notify("Downloading " .. target.url)
  local tmp = out .. ".part"
  vim.system(
    { "curl", "-fsSL", "--max-time", "90", "-A", UA, "-o", tmp, target.url },
    {},
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        os.remove(tmp)
        return notify("Download failed (" .. (r.stderr or ""):gsub("%s+$", "") .. ")", vim.log.levels.ERROR)
      end
      if not is_pdf(tmp) then
        os.remove(tmp)
        return notify(
          "That link is a web page, not a PDF. Add `pdf: <path or url>` to the note's frontmatter.",
          vim.log.levels.WARN
        )
      end
      os.rename(tmp, out)
      cb(out)
    end)
  )
end

-- ── Rendering ────────────────────────────────────────────────────────────

local function page_png(pdf, page)
  return ("%s/%s-p%d-%d"):format(cache .. "/pages", vim.fn.fnamemodify(pdf, ":t:r"), page, DPI)
end

local function render(pdf, page, cb)
  local prefix = page_png(pdf, page)
  if vim.fn.filereadable(prefix .. ".png") == 1 then
    return cb and cb(prefix .. ".png")
  end
  vim.fn.mkdir(cache .. "/pages", "p")
  vim.system(
    { "pdftoppm", "-f", tostring(page), "-l", tostring(page), "-r", tostring(DPI), "-png", "-singlefile", pdf, prefix },
    {},
    vim.schedule_wrap(function(r)
      if r.code ~= 0 then
        return cb and notify("Rendering page " .. page .. " failed", vim.log.levels.ERROR)
      end
      if cb then
        cb(prefix .. ".png")
      end
    end)
  )
end

local function page_text(pdf, page)
  local r = vim.system({ "pdftotext", "-f", tostring(page), "-l", tostring(page), "-layout", pdf, "-" }):wait()
  return vim.split((r.stdout or ""):gsub("\f", ""), "\n")
end

local function title()
  if not S then
    return
  end
  local name = vim.fn.fnamemodify(S.pdf, ":t")
  vim.wo[S.pdf_win].winbar = ("%%#Title# %s %%* page %d / %d  %%#Comment#(%s · ]p [p gp t r q)%%*"):format(
    name,
    S.page,
    S.pages,
    S.mode
  )
end

local function show()
  if not S or not vim.api.nvim_win_is_valid(S.pdf_win) then
    return
  end
  local buf = S.pdf_buf
  title()
  if S.mode == "text" then
    pcall(function()
      Snacks.image.placement.clean(buf)
    end)
    vim.bo[buf].modifiable = true
    vim.bo[buf].filetype = "text"
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, page_text(S.pdf, S.page))
    vim.bo[buf].modifiable = false
    vim.api.nvim_win_set_cursor(S.pdf_win, { 1, 0 })
    return
  end
  local page = S.page
  render(S.pdf, page, function(png)
    if not S or S.page ~= page or S.mode ~= "image" or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    Snacks.image.buf.attach(buf, { src = png })
  end)
  -- Prefetch the neighbours so turning pages is instant.
  for _, p in ipairs({ page + 1, page - 1 }) do
    if p >= 1 and p <= S.pages then
      render(S.pdf, p)
    end
  end
end

-- ── Session actions ──────────────────────────────────────────────────────

local function go(page)
  if not S then
    return notify("No PDF open — use :ReadingPdf", vim.log.levels.WARN)
  end
  S.page = math.max(1, math.min(S.pages, page))
  show()
end

local function note_win()
  if not S then
    return
  end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(w) == S.note_buf then
      return w
    end
  end
end

--- Appends `lines` after the cursor in the note (or at its end), then puts the
--- cursor there in insert mode if `insert` is set.
local function into_note(lines, insert)
  local w = note_win()
  if not w then
    return notify("The note isn't visible in this tab", vim.log.levels.WARN)
  end
  vim.api.nvim_set_current_win(w)
  local row = vim.api.nvim_win_get_cursor(w)[1]
  vim.api.nvim_buf_set_lines(S.note_buf, row, row, false, lines)
  vim.api.nvim_win_set_cursor(w, { row + #lines, #lines[#lines] })
  if insert then
    vim.cmd("startinsert!")
  end
end

local function remark()
  if S then
    into_note({ ("- p.%d: "):format(S.page) }, true)
  end
end

local function quote()
  if not S then
    return
  end
  vim.cmd('noautocmd normal! "zy')
  local text = vim.fn.getreg("z"):gsub("%s+", " "):gsub("^ ", ""):gsub(" $", "")
  if text ~= "" then
    into_note({ ("> %s (p.%d)"):format(text, S.page), "" }, false)
  end
end

local function jump_to_ref()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  -- Nearest `p.N` / `p. N` / `page N` on the line, preferring one under the cursor.
  local best, dist
  -- Word-bounded so "step 3" or "top10" don't count.
  for _, pat in ipairs({ "()%f[%w][pP]%.%s?(%d+)()", "()%f[%w][pP]age%s+(%d+)()" }) do
    for s, n, e in line:gmatch(pat) do
      local d = (col >= s and col < e) and 0 or math.min(math.abs(col - s), math.abs(col - e))
      if not dist or d < dist then
        best, dist = tonumber(n), d
      end
    end
  end
  if best then
    go(best)
  else
    notify("No page reference (p.N) on this line", vim.log.levels.WARN)
  end
end

function M.close()
  if not S then
    return
  end
  if vim.api.nvim_win_is_valid(S.pdf_win) then
    vim.api.nvim_win_close(S.pdf_win, true)
  end
  if vim.api.nvim_buf_is_valid(S.pdf_buf) then
    vim.api.nvim_buf_delete(S.pdf_buf, { force = true })
  end
  if vim.api.nvim_buf_is_valid(S.note_buf) then
    for _, lhs in ipairs({ ",r", ",g", ",n", ",p" }) do
      pcall(vim.keymap.del, "n", lhs, { buffer = S.note_buf })
    end
  end
  S = nil
end

local function open_pane(pdf, note_buf)
  local info = vim.system({ "pdfinfo", pdf }):wait()
  local pages = tonumber((info.stdout or ""):match("Pages:%s+(%d+)"))
  if not pages then
    return notify("Can't read " .. pdf, vim.log.levels.ERROR)
  end
  M.close()

  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  pcall(vim.api.nvim_buf_set_name, buf, "pdf://" .. vim.fn.fnamemodify(pdf, ":t"))
  vim.cmd("leftabove vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.55))
  for opt, v in pairs({ number = false, relativenumber = false, signcolumn = "no", wrap = false, cursorline = false }) do
    vim.wo[win][opt] = v
  end

  S = { pdf = pdf, pages = pages, page = 1, mode = "image", note_buf = note_buf, pdf_buf = buf, pdf_win = win }

  local function map(mode, lhs, fn, desc, b)
    vim.keymap.set(mode, lhs, fn, { buffer = b or buf, nowait = true, desc = "PDF: " .. desc })
  end
  map("n", "]p", function() go(S.page + 1) end, "next page")
  map("n", "[p", function() go(S.page - 1) end, "previous page")
  map("n", "<PageDown>", function() go(S.page + 1) end, "next page")
  map("n", "<PageUp>", function() go(S.page - 1) end, "previous page")
  map("n", "gp", function()
    vim.ui.input({ prompt = ("Page (1–%d): "):format(S.pages) }, function(v)
      if tonumber(v) then
        go(tonumber(v))
      end
    end)
  end, "go to page")
  map("n", "t", function()
    S.mode = S.mode == "image" and "text" or "image"
    show()
  end, "toggle image / text")
  map("n", "r", remark, "remark at this page")
  map("x", "Q", quote, "quote selection into note")
  map("n", "q", M.close, "close")

  map("n", ",r", remark, "remark at current page", note_buf)
  map("n", ",g", jump_to_ref, "jump to p.N under cursor", note_buf)
  map("n", ",n", function() go(S.page + 1) end, "next page", note_buf)
  map("n", ",p", function() go(S.page - 1) end, "previous page", note_buf)

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    once = true,
    callback = function()
      vim.schedule(function()
        if S and S.pdf_buf == buf then
          M.close()
        end
      end)
    end,
  })
  show()
end

--- Open the PDF for the current note (or `src`: path or URL).
function M.open(src)
  local note_buf = S and vim.api.nvim_get_current_buf() == S.pdf_buf and S.note_buf or vim.api.nvim_get_current_buf()
  local target, err = resolve(src, note_buf)
  if not target then
    return notify(err, vim.log.levels.WARN)
  end
  fetch(target, function(pdf)
    open_pane(pdf, note_buf)
  end)
end

function M.setup()
  vim.api.nvim_create_user_command("ReadingPdf", function(o)
    M.open(o.args ~= "" and o.args or nil)
  end, { nargs = "?", complete = "file", desc = "Open the note's PDF beside it (frontmatter pdf:/url:)" })
  vim.keymap.set("n", "<leader>op", "<cmd>ReadingPdf<cr>", { desc = "Reading: open PDF beside note" })
end

return M
