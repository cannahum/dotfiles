return {
  -- LazyVim's own core ui.lua opinion, not anything we asked for. Its buffer
  -- keymaps (<S-h>/<S-l>/[b/]b/etc.) live inside this same spec, so disabling
  -- it takes those down too — re-added below via plain :bprevious/:bnext.
  { "akinsho/bufferline.nvim", enabled = false },
  {
    "nvim-lua/plenary.nvim", -- always present; just a place to hang the keymaps
    keys = {
      { "<S-h>", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>bnext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>bprevious<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>bnext<cr>", desc = "Next Buffer" },
    },
  },
}
