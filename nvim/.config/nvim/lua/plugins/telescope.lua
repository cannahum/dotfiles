-- LazyVim's telescope extra wires <A-h>/<A-i> globally to "hidden"/"no_ignore",
-- but both closures are hardcoded to relaunch as find_files -- so pressing
-- <A-h> inside live_grep silently drops your grep and searches filenames
-- instead. Override it for live_grep specifically to actually widen the
-- current content search to hidden files (e.g. grepping across dotfiles),
-- matching what the keymap visually promises. <A-i> (no_ignore) is
-- deliberately left as-is -- grepping gitignored content (node_modules,
-- build output, ...) is usually more noise than it's worth.
return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      local live_grep_with_hidden = function()
        local line = require("telescope.actions.state").get_current_line()
        LazyVim.pick("live_grep", { hidden = true, default_text = line })()
      end

      opts.pickers = opts.pickers or {}
      opts.pickers.live_grep = vim.tbl_deep_extend("force", opts.pickers.live_grep or {}, {
        mappings = { i = { ["<a-h>"] = live_grep_with_hidden } },
      })

      return opts
    end,
  },
}
