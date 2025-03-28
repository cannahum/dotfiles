return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-tree/nvim-web-devicons",
    "folke/todo-comments.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")
    local actions = require("telescope.actions")
    local transform_mod = require("telescope.actions.mt").transform_mod

    local trouble = require("trouble")
    local trouble_telescope = require("trouble.sources.telescope")

    -- or create your custom action
    local custom_actions = transform_mod({
      open_trouble_qflist = function(prompt_bufnr)
        trouble.toggle("quickfix")
      end,
    })

    telescope.setup({
      defaults = {
        path_display = { "smart" },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- move to prev result
            ["<C-j>"] = actions.move_selection_next, -- move to next result
            ["<C-q>"] = actions.send_selected_to_qflist + custom_actions.open_trouble_qflist,
            ["<C-t>"] = trouble_telescope.open,
          },
        },
      },
      pickers = {
        live_grep = {
          file_ignore_patterns = { "^node_modules/", "^.git/", "^.venv/" },
          additional_args = function(_)
            return { "--hidden" }
          end,
        },
        find_files = {
          file_ignore_patterns = { "^node_modules/", "^.git/", "^.venv/" },
          -- hidden = true,
          -- no_ignore = true,
        },
      },
    })

    telescope.load_extension("fzf")

    -- set keymaps
    local keymap = vim.keymap -- for conciseness

    -- Source files only
    keymap.set("n", "<leader>ff", function()
      builtin.find_files({ hidden = false, no_ignore = false })
    end, { desc = "Find source files only" })

    keymap.set("n", "<leader>fs", function()
      builtin.live_grep({ hidden = false, no_ignore = false })
    end, { desc = "Live grep in source files only" })

    keymap.set("n", "<leader>fc", function()
      builtin.grep_string({ hidden = false, no_ignore = false })
    end, { desc = "Grep word under cursor in source files only" })

    -- Everything (including ignored & hidden files)
    keymap.set("n", "<leader>fF", function()
      builtin.find_files({ hidden = true, no_ignore = true })
    end, { desc = "Find all files (incl. ignored & hidden)" })

    keymap.set("n", "<leader>fS", function()
      builtin.live_grep({
        additional_args = function(_)
          return { "--hidden", "--no-ignore", "--no-ignore-vcs", "--smart-case" }
        end,
      })
    end, { desc = "Live grep in all files (incl. ignored & hidden)" })

    keymap.set("n", "<leader>fC", function()
      builtin.grep_string({ hidden = true, no_ignore = true })
    end, { desc = "Grep word under cursor in all files (incl. ignored & hidden)" })

    -- Find todos
    keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
  end,
}
