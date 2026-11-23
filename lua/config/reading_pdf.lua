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
--   PDF pane:  ]p [p  <PageDown> <PageUp>  <C-j> <C-k>  next / prev page
--              + (=) / - / 0   zoom in / out / reset    h j k l  pan while zoomed
--              w   fit the text column's width (sticks across pages; j/k scroll)
--              c   centre the view horizontally on the text (keeps zoom);
--                  at 100% it toggles centring the page in the pane
--              gp  go to page     t  toggle image / text view
--              r   remark at this page (jumps to the note)
--              Q   (visual, text view) quote selection into the note
--              q   close the PDF pane
--   Note:      ,r  remark at the current page    ,g  jump PDF to p.N under cursor
--              <C-j> <C-k>  next / prev PDF page
--              ,n / ,p  next / prev page

local M = {}

local cache = vim.fn.stdpath("cache") .. "/reading-pdfs"
local DPI = 150
-- Page renders not viewed for this long are deleted, and the oldest go first
-- once pages/ is over the cap. Zoomed views are deleted when the pane closes.
-- Downloaded PDFs are never pruned.
local PAGE_MAX_AGE_DAYS = 30
local PAGE_CACHE_MAX_MB = 500
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

--- `crop` (optional) = { dpi, x, y, w, h } in pixels at that dpi: renders only
--- that region of the page (used when zoomed in).
local function render(pdf, page, cb, crop)
  local prefix = page_png(pdf, page)
  local args = { "pdftoppm", "-f", tostring(page), "-l", tostring(page), "-r", tostring(DPI) }
  if crop then
    prefix = ("%s/zoom/%s-p%d-%d-%d-%d-%d-%d"):format(
      cache,
      vim.fn.fnamemodify(pdf, ":t:r"),
      page,
      crop.dpi,
      crop.x,
      crop.y,
      crop.w,
      crop.h
    )
    args = { "pdftoppm", "-f", tostring(page), "-l", tostring(page), "-r", tostring(crop.dpi) }
    vim.list_extend(args, { "-x", tostring(crop.x), "-y", tostring(crop.y), "-W", tostring(crop.w), "-H", tostring(crop.h) })
  end
  if vim.fn.filereadable(prefix .. ".png") == 1 then
    if not crop then
      local now = os.time()
      vim.uv.fs_utime(prefix .. ".png", now, now)
    end
    return cb and cb(prefix .. ".png")
  end
  vim.fn.mkdir(vim.fn.fnamemodify(prefix, ":h"), "p")
  vim.list_extend(args, { "-png", "-singlefile", pdf, prefix })
  vim.system(
    args,
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

--- Horizontal extent of the page's text as fractions of page width, or nil
--- (scanned page / no text). Uses text lines, ignoring short ones (line
--- numbers, page numbers, headers) and outliers (arXiv side stamp).
local function text_columns(pdf, page, pw)
  local r = vim.system({ "pdftotext", "-f", tostring(page), "-l", tostring(page), "-bbox-layout", pdf, "-" }):wait()
  local xs0, xs1 = {}, {}
  for x0, x1 in (r.stdout or ""):gmatch('<line xMin="([%d.]+)" yMin="[%d.]+" xMax="([%d.]+)"') do
    x0, x1 = tonumber(x0), tonumber(x1)
    if x1 - x0 > pw * 0.15 then
      xs0[#xs0 + 1], xs1[#xs1 + 1] = x0, x1
    end
  end
  if #xs0 < 3 then
    return nil
  end
  table.sort(xs0)
  table.sort(xs1)
  local lo = xs0[math.max(1, math.floor(#xs0 * 0.05))]
  local hi = xs1[math.min(#xs1, math.ceil(#xs1 * 0.95))]
  return lo / pw, hi / pw
end

local function title()
  if not S then
    return
  end
  local name = vim.fn.fnamemodify(S.pdf, ":t")
  local zoom = S.zoom > 1 and ("  zoom %d%%%%%s"):format(math.floor(S.zoom * 100 + 0.5), S.fit and " (fit width)" or "")
    or ""
  vim.wo[S.pdf_win].winbar = ("%%#Title# %s %%* page %d / %d%s  %%#Comment#(%s · ]p [p gp t r q  +/-/0 zoom  w fit  c centre  hjkl pan)%%*"):format(
    name,
    S.page,
    S.pages,
    zoom,
    S.mode
  )
end

--- Size of the visible part of the page, as fractions of page width / height.
local function viewport()
  local vw = 1 / S.zoom
  local cw, ch = 1, 2 -- fallback cell aspect
  pcall(function()
    local t = Snacks.image.terminal.size()
    cw, ch = t.cell_width, t.cell_height
  end)
  local win_w = vim.api.nvim_win_get_width(S.pdf_win) * cw
  local win_h = vim.api.nvim_win_get_height(S.pdf_win) * ch
  local vh = vw * (win_h / win_w) * (S.pw / S.ph)
  return vw, math.min(1, vh)
end

local function clamp_pan()
  local vw, vh = viewport()
  S.x = math.max(0, math.min(1 - vw, S.x))
  S.y = math.max(0, math.min(1 - vh, S.y))
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
  if S.fit and S.fit_page ~= S.page then
    M.fit_width()
  end
  local crop
  if S.zoom > 1 then
    clamp_pan()
    local vw, vh = viewport()
    local dpi = math.floor(DPI * S.zoom + 0.5)
    local pw, ph = S.pw / 72 * dpi, S.ph / 72 * dpi
    crop = {
      dpi = dpi,
      x = math.floor(S.x * pw),
      y = math.floor(S.y * ph),
      w = math.floor(vw * pw),
      h = math.floor(vh * ph),
    }
  end
  -- Centred at 100%: pad the page with white on both sides to the pane's
  -- aspect ratio (only when the pane is wider than the page).
  local pad_w
  if not crop and S.centre then
    local cw, ch = 1, 2
    pcall(function()
      local t = Snacks.image.terminal.size()
      cw, ch = t.cell_width, t.cell_height
    end)
    local win_ratio = (vim.api.nvim_win_get_width(S.pdf_win) * cw) / (vim.api.nvim_win_get_height(S.pdf_win) * ch)
    local img_w, img_h = math.floor(S.pw / 72 * DPI), math.floor(S.ph / 72 * DPI)
    local w = math.floor(img_h * win_ratio)
    if w > img_w + 2 then
      pad_w = w
    end
  end
  local key = vim.inspect(crop) .. tostring(pad_w)
  S.view = key
  local function attach(png)
    if not S or S.page ~= page or S.view ~= key or S.mode ~= "image" or not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
    Snacks.image.buf.attach(buf, { src = png })
  end
  render(S.pdf, page, function(png)
    if not pad_w then
      return attach(png)
    end
    local out = ("%s/zoom/%s-p%d-c%d.png"):format(cache, vim.fn.fnamemodify(S.pdf, ":t:r"), page, pad_w)
    if vim.fn.filereadable(out) == 1 then
      return attach(out)
    end
    vim.fn.mkdir(cache .. "/zoom", "p")
    vim.system(
      { "magick", png, "-background", "white", "-gravity", "center", "-extent", pad_w .. "x", out },
      {},
      vim.schedule_wrap(function(r)
        attach(r.code == 0 and out or png)
      end)
    )
  end, crop)
  -- Prefetch the neighbours so turning pages is instant.
  for _, p in ipairs({ page + 1, page - 1 }) do
    if p >= 1 and p <= S.pages then
      render(S.pdf, p)
    end
  end
end

-- ── Session actions ──────────────────────────────────────────────────────

--- Zoom so the page's text column(s) fill the pane's width, margins cropped.
--- Only sets S.zoom / S.x (show() calls this while S.fit is on).
function M.fit_width()
  local lo, hi = text_columns(S.pdf, S.page, S.pw)
  if not lo then
    lo, hi = 0, 1
  end
  local pad = 0.015
  lo, hi = math.max(0, lo - pad), math.min(1, hi + pad)
  S.zoom = math.max(1, math.min(6, 1 / (hi - lo)))
  S.x = lo
  S.fit_page = S.page
end

local function go(page)
  if not S then
    return notify("No PDF open — use :ReadingPdf", vim.log.levels.WARN)
  end
  local new = math.max(1, math.min(S.pages, page))
  if new ~= S.page then
    S.y = 0
  end
  S.page = new
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

-- ── Cache cleanup ───────────────────────────────────────────────────────

--- Deletes this PDF's zoomed views (cheap to re-render, rarely reused).
local function drop_zoom(pdf)
  local name = vim.fn.fnamemodify(pdf, ":t:r")
  for _, f in ipairs(vim.fn.glob(cache .. "/zoom/" .. name .. "-p*.png", false, true)) do
    vim.uv.fs_unlink(f)
  end
end

--- Drops page renders older than PAGE_MAX_AGE_DAYS, then the least recently
--- viewed ones until pages/ fits PAGE_CACHE_MAX_MB. Also clears zoomed views
--- left behind by crashed / killed sessions (older than a day).
local function prune()
  local now = os.time()
  local function scan(dir)
    local out = {}
    for _, f in ipairs(vim.fn.glob(dir .. "/*.png", false, true)) do
      local st = vim.uv.fs_stat(f)
      if st then
        out[#out + 1] = { path = f, mtime = st.mtime.sec, size = st.size }
      end
    end
    return out
  end
  for _, f in ipairs(scan(cache .. "/zoom")) do
    if now - f.mtime > 86400 then
      vim.uv.fs_unlink(f.path)
    end
  end
  local keep, total = {}, 0
  for _, f in ipairs(scan(cache .. "/pages")) do
    if now - f.mtime > PAGE_MAX_AGE_DAYS * 86400 then
      vim.uv.fs_unlink(f.path)
    else
      keep[#keep + 1] = f
      total = total + f.size
    end
  end
  table.sort(keep, function(a, b)
    return a.mtime < b.mtime
  end)
  local cap = PAGE_CACHE_MAX_MB * 1024 * 1024
  for _, f in ipairs(keep) do
    if total <= cap then
      break
    end
    vim.uv.fs_unlink(f.path)
    total = total - f.size
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
    for _, lhs in ipairs({ ",r", ",g", ",n", ",p", "<C-j>", "<C-k>" }) do
      pcall(vim.keymap.del, "n", lhs, { buffer = S.note_buf })
    end
  end
  drop_zoom(S.pdf)
  S = nil
end

local function open_pane(pdf, note_buf)
  local info = vim.system({ "pdfinfo", pdf }):wait()
  local pages = tonumber((info.stdout or ""):match("Pages:%s+(%d+)"))
  if not pages then
    return notify("Can't read " .. pdf, vim.log.levels.ERROR)
  end
  M.close()
  vim.schedule(prune)

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

  local pw, ph = (info.stdout or ""):match("Page size:%s+([%d.]+) x ([%d.]+)")
  S = {
    pdf = pdf,
    pages = pages,
    page = 1,
    mode = "image",
    note_buf = note_buf,
    pdf_buf = buf,
    pdf_win = win,
    zoom = 1,
    fit = false,
    centre = false,
    x = 0,
    y = 0,
    pw = tonumber(pw) or 612,
    ph = tonumber(ph) or 792,
  }

  local function map(mode, lhs, fn, desc, b)
    vim.keymap.set(mode, lhs, fn, { buffer = b or buf, nowait = true, desc = "PDF: " .. desc })
  end
  map("n", "]p", function() go(S.page + 1) end, "next page")
  map("n", "[p", function() go(S.page - 1) end, "previous page")
  map("n", "<PageDown>", function() go(S.page + 1) end, "next page")
  map("n", "<PageUp>", function() go(S.page - 1) end, "previous page")
  -- <C-j>/<C-k> turn pages from either pane (overrides window-nav there).
  for _, b in ipairs({ buf, note_buf }) do
    map("n", "<C-j>", function() go(S.page + 1) end, "next page", b)
    map("n", "<C-k>", function() go(S.page - 1) end, "previous page", b)
  end
  map("n", "gp", function()
    vim.ui.input({ prompt = ("Page (1–%d): "):format(S.pages) }, function(v)
      if tonumber(v) then
        go(tonumber(v))
      end
    end)
  end, "go to page")
  -- Zoom: + / = in, - out, 0 reset. hjkl pan while zoomed (move the cursor in text mode).
  local function zoom(z)
    if S.mode ~= "image" then
      return
    end
    local vw, vh = viewport()
    local cx, cy = S.x + vw / 2, S.y + vh / 2 -- keep the centre fixed
    S.fit = false
    S.zoom = math.max(1, math.min(6, z))
    vw, vh = viewport()
    S.x, S.y = cx - vw / 2, cy - vh / 2
    show()
  end
  map("n", "+", function() zoom(S.zoom * 1.5) end, "zoom in")
  map("n", "=", function() zoom(S.zoom * 1.5) end, "zoom in")
  map("n", "-", function() zoom(S.zoom / 1.5) end, "zoom out")
  map("n", "0", function() zoom(1) end, "reset zoom")
  for key, d in pairs({ h = { -1, 0 }, l = { 1, 0 }, k = { 0, -1 }, j = { 0, 1 } }) do
    map("n", key, function()
      if S.mode ~= "image" or S.zoom <= 1 then
        return vim.cmd("normal! " .. vim.v.count1 .. key)
      end
      local vw, vh = viewport()
      -- Small sideways steps so the view can be lined up with the text.
      S.x = S.x + d[1] * vw / 8 * vim.v.count1
      S.y = S.y + d[2] * vh / 3 * vim.v.count1
      show()
    end, "pan " .. key)
  end
  map("n", "w", function()
    if S.mode ~= "image" then
      return vim.cmd("normal! " .. vim.v.count1 .. "w")
    end
    S.fit, S.fit_page = true, nil
    show()
  end, "fit text width")
  map("n", "c", function()
    if S.mode ~= "image" then
      return
    end
    if S.zoom <= 1 then
      S.centre = not S.centre
      return show()
    end
    local lo, hi = text_columns(S.pdf, S.page, S.pw)
    local mid = lo and (lo + hi) / 2 or 0.5
    S.x = mid - viewport() / 2
    show()
  end, "centre horizontally on text")
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
  -- Start in the note so you can write right away.
  local nw = note_win()
  if nw then
    vim.api.nvim_set_current_win(nw)
  end
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
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if S then
        drop_zoom(S.pdf)
      end
    end,
  })
  vim.api.nvim_create_user_command("ReadingPdf", function(o)
    M.open(o.args ~= "" and o.args or nil)
  end, { nargs = "?", complete = "file", desc = "Open the note's PDF beside it (frontmatter pdf:/url:)" })
  vim.keymap.set("n", "<leader>op", "<cmd>ReadingPdf<cr>", { desc = "Reading: open PDF beside note" })
end

return M
