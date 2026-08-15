return {
  -- LazyVim's own core util.lua opinion, running redundantly alongside our
  -- own auto-session.lua (which has real tuning — suppress_dirs — that
  -- persistence.nvim doesn't offer). Two session-management backends
  -- watching the same directories isn't needed.
  { "folke/persistence.nvim", enabled = false },
}
