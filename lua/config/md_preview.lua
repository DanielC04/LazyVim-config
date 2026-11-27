-- Preview of a markdown file inside nvim: glow's rendering (as with <leader>og)
-- in a pane left of the source, the same layout as the PDF/Typst preview.
-- The cursor stays in the preview so you can scroll it right away; it is
-- re-rendered on save of the source, keeping the scroll position.
--
--   <leader>op (in .md buffers)   toggle the preview
--     Reading notes (frontmatter pdf: or url:) keep <leader>op = :ReadingPdf.
--   :MdPreview                    toggle the preview for any markdown buffer
--   Preview pane:  j/k, <C-d>/<C-u>, gg/G scroll   q close   <C-l> to source

local M = {}

local group = vim.api.nvim_create_augroup("MdPreview", { clear = true })

---@type { src_buf: integer, win: integer, buf: integer? }?
local P = nil

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Markdown preview" })
end

local function is_reading_note(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, 200, false)
  if lines[1] ~= "---" then
    return false
  end
  for i = 2, #lines do
    if lines[i] == "---" then
      return false
    end
    if lines[i]:match("^pdf:%s*%S") or lines[i]:match("^url:%s*%S") then
      return true
    end
  end
  return false
end

function M.close()
  local p = P
  P = nil
  vim.api.nvim_clear_autocmds({ group = group })
  if p and vim.api.nvim_win_is_valid(p.win) then
    pcall(vim.api.nvim_win_close, p.win, true)
  end
end

-- Renders the source file (as saved on disk) into a fresh terminal buffer in
-- the preview window. `line` restores the scroll position after a re-render.
local function render(line)
  local p = P
  if not p or not vim.api.nvim_win_is_valid(p.win) then
    return M.close()
  end
  local file = vim.api.nvim_buf_get_name(p.src_buf)
  local old = p.buf
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_win_set_buf(p.win, buf)
  p.buf = buf
  if old and vim.api.nvim_buf_is_valid(old) then
    pcall(vim.api.nvim_buf_delete, old, { force = true })
  end

  local width = math.max(40, vim.api.nvim_win_get_width(p.win) - 2)
  vim.api.nvim_win_call(p.win, function()
    vim.fn.jobstart({ "glow", "-s", vim.o.background, "-w", tostring(width), file }, {
      term = true,
      on_exit = vim.schedule_wrap(function()
        if P ~= p or p.buf ~= buf or not vim.api.nvim_win_is_valid(p.win) then
          return
        end
        -- Drop the "[Process exited 0]" line and trailing blanks.
        local n = vim.api.nvim_buf_line_count(buf)
        local last = n
        while last > 1 do
          local l = vim.api.nvim_buf_get_lines(buf, last - 1, last, false)[1]
          if l:match("%S") and not l:match("^%[Process exited") then
            break
          end
          last = last - 1
        end
        vim.bo[buf].modifiable = true
        pcall(vim.api.nvim_buf_set_lines, buf, last, n, false, {})
        vim.bo[buf].modifiable = false
        local target = math.min(line or 1, vim.api.nvim_buf_line_count(buf))
        pcall(vim.api.nvim_win_set_cursor, p.win, { target, 0 })
        vim.api.nvim_win_call(p.win, function()
          vim.cmd("normal! zt")
        end)
      end),
    })
  end)
  pcall(vim.api.nvim_buf_set_name, buf, "glow://" .. vim.fn.fnamemodify(file, ":t"))

  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, desc = "Preview: " .. desc })
  end
  map("q", M.close, "close")
  map("<C-l>", function()
    local w = vim.fn.bufwinid(p.src_buf)
    if w ~= -1 then
      vim.api.nvim_set_current_win(w)
    end
  end, "go to source")
  -- Keep normal mode on entering the pane (terminal buffers would start insert).
  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    buffer = buf,
    callback = function()
      vim.cmd("stopinsert")
    end,
  })
end

function M.open()
  local src_buf = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(src_buf)
  if file == "" or vim.fn.filereadable(file) == 0 then
    return notify("Save the file first", vim.log.levels.WARN)
  end
  if vim.fn.executable("glow") == 0 then
    return notify("glow not found", vim.log.levels.ERROR)
  end
  M.close()

  vim.cmd("leftabove vsplit")
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(win, math.floor(vim.o.columns * 0.55))
  for opt, v in pairs({ number = false, relativenumber = false, signcolumn = "no", wrap = false, spell = false }) do
    vim.wo[win][opt] = v
  end
  P = { src_buf = src_buf, win = win }
  render(1)

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = src_buf,
    callback = function()
      if P and vim.api.nvim_win_is_valid(P.win) then
        local top = vim.api.nvim_win_call(P.win, function()
          return vim.fn.line("w0")
        end)
        render(top)
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group,
    pattern = tostring(win),
    callback = function()
      vim.schedule(function()
        if P and P.win == win then
          M.close()
        end
      end)
    end,
  })
  -- Focus stays in the preview pane (opened by the vsplit above).
end

function M.toggle()
  if P then
    return M.close()
  end
  M.open()
end

function M.setup()
  vim.api.nvim_create_user_command("MdPreview", M.toggle, { desc = "Toggle glow preview of this markdown file in a pane" })
  local function map(buf)
    vim.keymap.set("n", "<leader>op", function()
      if not P and is_reading_note(buf) then
        return vim.cmd("ReadingPdf")
      end
      M.toggle()
    end, { buffer = buf, desc = "Markdown preview (reading notes: open PDF)" })
  end
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(ev)
      map(ev.buf)
    end,
  })
  -- Buffers opened before this ran (keymaps load late).
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "markdown" then
      map(b)
    end
  end
end

return M
