-- Preview of a Typst file inside nvim: shows the PDF beside the source with
-- the reading_pdf viewer (snacks.image in kitty) and rebuilds it on save.
-- Each rebuild re-renders in place; page, zoom and pan stay put.
--
-- Builds compile the file on disk with the git root as root; errors are
-- reported and the last good PDF is kept.
--
-- Needs a non-snap typst (~/.local/bin/typst): the snap is confined and can't
-- read files under /documents.
--
--   :TypstPreview   <leader>op (in .typ buffers)   toggle the preview
--   PDF pane keys as in reading_pdf.lua (]p [p, +/-/0, w, gp, t, q)
--   <C-j>/<C-k> or ,n/,p in the source turn pages.

local M = {}

local pdfview = require("config.reading_pdf")
local group = vim.api.nvim_create_augroup("TypstPreview", { clear = true })

---@type { src: string, pdf: string, buf: integer, running: boolean, queued: table? }?
local P = nil

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Typst preview" })
end

local function stop()
  P = nil
  vim.api.nvim_clear_autocmds({ group = group })
end

--- Builds P.pdf from the file on disk, reporting errors. `cb(ok)` runs after.
--- A request during a build is queued (only the latest one is kept).
local function compile(cb)
  local p = P
  if not p then
    return
  end
  if p.running then
    p.queued = { cb = cb }
    return
  end
  local dir = vim.fn.fnamemodify(p.src, ":h")
  local root = vim.fs.root(p.src, ".git")
  root = root and vim.uv.fs_realpath(root) or dir
  local cmd = { "typst", "compile", "--root", root, p.src, p.pdf }
  p.running = true
  vim.system(
    cmd,
    { cwd = dir },
    vim.schedule_wrap(function(r)
      p.running = false
      if P ~= p then
        return
      end
      if r.code ~= 0 then
        local out = ((r.stderr or "") .. (r.stdout or "")):gsub("\27%[[%d;?]*%a", "")
        local first = out:match("(error:[^\n]*)") or out:match("[^\n]+") or ("exit " .. r.code)
        local where = out:match("┌─%s*([^\n]+)")
        notify(first .. (where and ("\n" .. vim.fn.fnamemodify(where, ":t")) or ""), vim.log.levels.WARN)
      end
      if cb then
        cb(r.code == 0)
      end
      local q = p.queued
      if q then
        p.queued = nil
        compile(q.cb)
      end
    end)
  )
end

local function rebuild()
  local pdf = P and P.pdf
  compile(function(ok)
    if ok then
      pdfview.reload(pdf)
    end
  end)
end

function M.start()
  local src = vim.api.nvim_buf_get_name(0)
  if not src:match("%.typ$") then
    return notify("Not a .typ file", vim.log.levels.WARN)
  end
  stop()
  local buf = vim.api.nvim_get_current_buf()
  if vim.fn.exepath("typst"):match("/snap/") then
    return notify("typst is the snap (can't read /documents). Install the release binary to ~/.local/bin.", vim.log.levels.ERROR)
  end
  P = { src = src, pdf = (src:gsub("%.typ$", ".pdf")), buf = buf, running = false }
  local pdf = P.pdf

  -- First build from the saved file; unsaved edits show after the next save.
  compile(function(ok)
    if not P or P.pdf ~= pdf then
      return
    end
    if not ok and vim.fn.filereadable(pdf) == 0 then
      stop()
      return notify("Build failed, no PDF to show", vim.log.levels.WARN)
    end
    local w = vim.fn.bufwinid(buf)
    if w == -1 then
      return stop()
    end
    vim.api.nvim_set_current_win(w)
    pdfview.preview(pdf, function()
      if P and P.pdf == pdf then
        stop()
      end
    end)
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = group,
      buffer = buf,
      callback = function()
        rebuild()
      end,
    })
  end)
end

function M.toggle()
  if P then
    local pdf = P.pdf
    stop()
    if pdfview.current() == pdf then
      pdfview.close()
    end
    return
  end
  M.start()
end

function M.setup()
  vim.api.nvim_create_user_command("TypstPreview", M.toggle, { desc = "Toggle Typst preview in a pane (rebuilds on save)" })
  local function map(buf)
    vim.keymap.set("n", "<leader>op", M.toggle, { buffer = buf, desc = "Typst: toggle preview" })
  end
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "typst",
    callback = function(ev)
      map(ev.buf)
    end,
  })
  -- Buffers opened before this ran (keymaps load late).
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and vim.bo[b].filetype == "typst" then
      map(b)
    end
  end
end

return M
