-- obsidian.nvim (maintained fork: obsidian-nvim/obsidian.nvim; epwalsh/obsidian.nvim is archived)
-- Link completion comes from the plugin's built-in LSP server ("obsidian-ls"), which blink.cmp
-- picks up through its default "lsp" source: type [[ plus 2 chars to get note names and aliases.
local vault = "/documents/Notes"

return {
  {
    "obsidian-nvim/obsidian.nvim",
    version = "*", -- latest release instead of main
    lazy = true,
    event = {
      "BufReadPre " .. vault .. "/**.md",
      "BufNewFile " .. vault .. "/**.md",
    },
    cmd = "Obsidian",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>oo", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch note" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ol", "<cmd>Obsidian links<cr>", desc = "Links in note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search vault" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Tags" },
      { "<leader>od", "<cmd>Obsidian today<cr>", desc = "Daily note (today)" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note (updates links)" },
      { "<leader>oT", "<cmd>Obsidian template<cr>", desc = "Insert template" },
      { "<leader>ol", ":Obsidian link<cr>", mode = "v", desc = "Link selection to note" },
      { "<leader>ox", ":Obsidian extract_note<cr>", mode = "v", desc = "Extract selection to new note" },
    },
    ---@module 'obsidian'
    ---@type obsidian.config
    opts = {
      legacy_commands = false, -- only the new `:Obsidian <subcommand>` form
      workspaces = {
        { name = "Notes", path = vault },
      },
      -- keep links like the existing ones: [[Note name]]
      link = { style = "wiki", format = "shortest" },
      completion = {
        min_chars = 2,
        match_case = false,
        create_new = true,
      },
      -- note id = title, file name = "<title>.md" (matches existing notes)
      note_id_func = function(title)
        if title ~= nil and title ~= "" then
          return title
        end
        local suffix = ""
        for _ = 1, 4 do
          suffix = suffix .. string.char(math.random(65, 90))
        end
        return suffix
      end,
      -- frontmatter id / aliases / tags + "# Title" heading (template lives in the nvim config, not the vault)
      note = {
        template = vim.fn.stdpath("config") .. "/templates/obsidian-note.md",
      },
      frontmatter = { sort = { "id", "aliases", "tags" } },
      daily_notes = {
        folder = "dailies",
        date_format = "%d-%m-%Y",
        alias_format = "%A, %d %B %Y",
        template = "daily-note.md",
      },
      templates = {
        folder = "templates",
        date_format = "%Y-%m-%d-%a",
        time_format = "%H:%M",
        substitutions = {
          writtendate = function()
            return os.date("%A, %d. %B %Y")
          end,
          yesterday = function()
            return os.date("%Y-%m-%d", os.time() - 86400)
          end,
        },
      },
      attachments = { folder = "media" },
      -- in-buffer rendering is done by render-markdown.nvim (see render-markdown.lua)
      ui = { enable = false },
      callbacks = {
        enter_note = function()
          -- gf follows [[links]] inside notes, falls back to normal gf otherwise.
          -- <CR> (smart action: follow link / toggle checkbox) is mapped by obsidian.nvim itself.
          vim.keymap.set("n", "gf", function()
            if require("obsidian.api").cursor_link() then
              return "<cmd>Obsidian follow_link<cr>"
            end
            return "gf"
          end, { buffer = true, expr = true, desc = "Follow link" })
        end,
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    opts = { spec = { { "<leader>o", group = "obsidian", icon = "󰠮" } } },
  },
}
