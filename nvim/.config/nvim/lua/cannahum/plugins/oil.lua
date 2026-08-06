-- Declare a global function to retrieve the current directory for the winbar
function _G.get_oil_winbar()
  local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid)
  local dir = require("oil").get_current_dir(bufnr)
  if dir then
    return vim.fn.fnamemodify(dir, ":~")
  else
    return vim.api.nvim_buf_get_name(0)
  end
end

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false,
  keys = {
    { "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
    { "<leader>ee", "<cmd>Oil<CR>", desc = "Open file explorer" },
  },
  opts = {
    default_file_explorer = false,
    view_options = {
      show_hidden = true,
    },
    win_options = {
      winbar = "%!v:lua.get_oil_winbar()",
    },
    -- free up <C-h>/<C-l> so vim-tmux-navigator can move between splits/panes
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<leader>er"] = "actions.refresh",
    },
  },
}
