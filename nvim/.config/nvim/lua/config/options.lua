require("config.remote_clipboard").setup()

-- Without an explicit lazyvim.json, LazyVim's own "pick a default" resolver
-- for these three categories runs (see lazyvim.config.init M.get_defaults) —
-- it does NOT detect what's already in lua/plugins/, it just falls back to a
-- fixed priority list (snacks picker, blink.cmp, snacks/neo-tree explorer).
-- That silently pulled in blink.cmp alongside our own nvim-cmp and crashed
-- alpha's startup screen trying to load the snacks picker extra. Pin these
-- explicitly to what lua/plugins/ actually provides. Must live here, not in
-- config/lazy.lua: LazyVim.config.init() loads its own config/options.lua
-- (which sets these to "auto") before loading this file, so anything set
-- earlier than this gets clobbered.
vim.g.lazyvim_picker = "telescope"
vim.g.lazyvim_cmp = "nvim-cmp"
vim.g.lazyvim_explorer = "neo-tree" -- oil.lua is the real explorer; unused but must pick one

-- LazyVim's own defaults already cover most of what used to be set by hand
-- here (relativenumber, tabstop/shiftwidth=2, ignorecase/smartcase, cursorline,
-- termguicolors, signcolumn=yes, splitright/splitbelow, clipboard=unnamedplus,
-- wrap=false) — see lazyvim/config/options.lua. Only the real deltas are left.
vim.opt.scrolloff = 8 -- LazyVim defaults to 4

vim.diagnostic.config({
  virtual_text = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.HINT] = "󰠠 ",
      [vim.diagnostic.severity.INFO] = " ",
    },
  },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
