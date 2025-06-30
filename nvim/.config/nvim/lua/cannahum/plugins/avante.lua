return {
  "yetone/avante.nvim",
  build = function()
    if vim.fn.has("win32") == 1 then
      return "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
    else
      return "make"
    end
  end,
  event = "VeryLazy",
  version = false,
  opts = {
    provider = "openai",
    providers = {
      openai = {
        model = os.getenv("AVANTE_MODEL") or "gpt-4o-mini",
        endpoint = os.getenv("OPENAI_API_BASE") or "https://api.openai.com/v1",
        api_key = os.getenv("OPENAI_API_KEY"),
        timeout = 30000,
      },
    },
    behaviour = {
      auto_suggestions = false,
      auto_set_keymaps = true,
      auto_apply_diff_after_generation = false,
    },
    -- system_prompt as function ensures LLM always has latest MCP server state
    -- This is evaluated for every message, even in existing chats
    system_prompt = function()
      local hub = require("mcphub").get_hub_instance()
      return hub and hub:get_active_servers_prompt() or ""
    end,
    -- Using function prevents requiring mcphub before it's loaded
    custom_tools = function()
      return {
        require("mcphub.extensions.avante").mcp_tool(),
      }
    end,
  },
  config = function(_, opts)
    require("avante_lib").load()
    require("avante").setup(opts)
    vim.keymap.set("n", "<leader>it", "<cmd>AvanteChat<CR>", { desc = "Toggle sidebar visibility" })
    vim.keymap.set("n", "<leader>i?", "<cmd>AvanteModels<CR>", { desc = "Select model" })
    vim.keymap.set("n", "<leader>is", "<cmd>AvanteStop<CR>", { desc = "Toggle chat sidebar" })
  end,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    "echasnovski/mini.pick",
    "nvim-telescope/telescope.nvim",
    "hrsh7th/nvim-cmp",
    "ibhagwan/fzf-lua",
    "stevearc/dressing.nvim",
    "folke/snacks.nvim",
    "nvim-tree/nvim-web-devicons",
    {
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
          use_absolute_path = true,
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
}
