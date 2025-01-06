local keymap = vim.keymap

local function resize_nvim_tree(amount)
  local view = require("nvim-tree.view")

  if not view.is_visible() then
    vim.notify("nvim-tree is not visible", vim.log.levels.INFO)
    return
  end

  -- Adjust width dynamically
  local current_width = view.View.width or 30 -- Default width
  local new_width = math.max(current_width + amount, 1) -- Ensure minimum width
  view.View.width = new_width
  view.resize(new_width)

  -- Persist the width for the session
  vim.g.nvim_tree_width = new_width
end

keymap.set("n", "<leader>>", function()
  resize_nvim_tree(5)
end, { desc = "Increase nvim-tree width" })
keymap.set("n", "<leader><", function()
  resize_nvim_tree(-5)
end, { desc = "Decrease nvim-tree width" })

-- Restore width on startup
vim.g.nvim_tree_width = vim.g.nvim_tree_width or 30

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup({
      view = {
        width = vim.g.nvim_tree_width,
        relativenumber = true,
      },
      update_focused_file = {
        enable = true,
        update_cwd = false,
      },
      -- change folder arrow icons
      renderer = {
        indent_markers = {
          enable = true,
        },
        icons = {
          glyphs = {
            folder = {
              arrow_closed = "", -- arrow when folder is closed
              arrow_open = "", -- arrow when folder is open
            },
          },
        },
      },
      -- disable window_picker for
      -- explorer to work well with
      -- window splits
      actions = {
        open_file = {
          window_picker = {
            enable = false,
          },
        },
      },
      filters = {
        custom = { ".DS_Store" },
      },
      git = {
        ignore = false,
      },
    })

    keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
    keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
    keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
    keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
  end,
}
