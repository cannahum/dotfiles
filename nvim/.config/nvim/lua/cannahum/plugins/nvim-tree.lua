local keymap = vim.keymap

-- Restore width on startup
vim.g.nvim_tree_width = vim.g.nvim_tree_width or 40

local initial_nvim_tree_setup = {
  view = {
    width = vim.g.nvim_tree_width,
    relativenumber = true,
  },
  update_focused_file = {
    enable = true,
    update_cwd = false,
  }, -- these are modified by functions above
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
        enable = true,
        chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", -- You can specify the characters used for window labels
      },
    },
  },
  filters = {
    custom = { ".DS_Store" },
  },
  git = {
    ignore = false,
  },
}

local function enable_nvim_tree_tracking()
  -- Reinitialize nvim-tree with updated setting
  initial_nvim_tree_setup.update_focused_file.enable = true
  require("nvim-tree").setup(initial_nvim_tree_setup)
  vim.cmd("NvimTreeToggle")
  print("enabled nvim-tree focused file tracking")
end

local function disable_nvim_tree_tracking()
  -- Reinitialize nvim-tree with updated setting
  initial_nvim_tree_setup.update_focused_file.enable = false
  require("nvim-tree").setup(initial_nvim_tree_setup)
  vim.cmd("NvimTreeToggle")
  print("disabled nvim-tree focused file tracking")
end

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

return {
  "nvim-tree/nvim-tree.lua",
  dependencies = "nvim-tree/nvim-web-devicons",
  config = function()
    local nvimtree = require("nvim-tree")

    -- recommended settings from nvim-tree documentation
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1

    nvimtree.setup(initial_nvim_tree_setup)

    keymap.set("n", "<leader>ee", "<cmd>NvimTreeToggle<CR>", { desc = "Toggle file explorer" }) -- toggle file explorer
    keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFileToggle<CR>", { desc = "Toggle file explorer on current file" }) -- toggle file explorer on current file
    keymap.set("n", "<leader>ec", "<cmd>NvimTreeCollapse<CR>", { desc = "Collapse file explorer" }) -- collapse file explorer
    keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" }) -- refresh file explorer
    keymap.set(
      "n",
      "<leader>etd",
      disable_nvim_tree_tracking,
      { desc = "Disable nvim-tree update_focused_file (tracking)" }
    )
    keymap.set(
      "n",
      "<leader>ete",
      enable_nvim_tree_tracking,
      { desc = "Enable nvim-tree update_focused_file (tracking)" }
    )
    keymap.set("n", "<leader>>", function()
      resize_nvim_tree(5)
    end, { desc = "Increase nvim-tree width" })
    keymap.set("n", "<leader><", function()
      resize_nvim_tree(-5)
    end, { desc = "Decrease nvim-tree width" })
  end,
}
