return {
  "olimorris/codecompanion.nvim",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local cc = require("codecompanion")
    cc.setup({
      adapters = {
        openai = function()
          print("✅ Loading OpenAI adapter")
          return require("codecompanion.adapters").extend("openai", {
            env = {
              api_key = os.getenv("CHATGPT_TOKEN"),
            },
            opts = {
              stream = true,
              -- tools = {
              --   {
              --     type = "mcp",
              --     server_label = "deepwiki",
              --     server_url = "https://mcp.deepwiki.com/mcp",
              --   },
              -- },
            },
            schema = {
              model = {
                default = function()
                  return "gpt-4o"
                end,
              },
            },
          })
        end,
        copilot = function()
          return require("codecompanion.adapters").extend("copilot", {
            schema = {
              model = {
                default = "gpt-4.1", -- This is ignored, Copilot uses its own backend
              },
            },
          })
        end,
      },
      strategies = {
        chat = {
          adapter = "openai", -- Chat uses GPT-4o
        },
        inline = {
          adapter = "copilot", -- Inline completions from Copilot
        },
      },
    })
    -- Key mappings
    local keymap = vim.keymap.set
    keymap("n", "<leader>ii", function()
      cc.inline({})
    end, { desc = "Trigger CodeCompanion Inline (Copilot)" })

    keymap("n", "<leader>ic", function()
      cc.chat()
    end, { desc = "Trigger CodeCompanion Chat (OpenAI)" })

    keymap("n", "<leader>it", function()
      cc.toggle()
    end, { desc = "Toggle CodeCompanion Panel" })
  end,
}
