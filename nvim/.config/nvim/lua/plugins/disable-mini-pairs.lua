return {
  -- LazyVim's own core coding.lua opinion, running alongside our own
  -- autopairs.lua (kept deliberately -- its cmp_autopairs.on_confirm_done()
  -- hook isn't something mini.pairs replicates). Two auto-pairing backends
  -- both hooking insert-mode typing is fragile even where the simple case
  -- looks fine; keep only the one we chose.
  { "nvim-mini/mini.pairs", enabled = false },
}
