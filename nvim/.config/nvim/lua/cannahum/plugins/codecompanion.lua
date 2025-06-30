return {
  "olimorris/codecompanion.nvim",
  enabled = false,
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local cc = require("codecompanion")
    -- 🤖 Current model (default)
    local current_model = "gpt-4o-mini"
    -- 🧠 Define model selector function
    local function choose_model()
      local models = {
        ["1"] = "gpt-4o",
        ["2"] = "gpt-4o-mini",
        ["3"] = "gpt-4.1",
        ["4"] = "gpt-3.5-turbo",
      }
      local choice = vim.fn.input([[
Choose OpenAI model:
1. gpt-4o
2. gpt-4o-mini
3. gpt-4.1
4. gpt-3.5-turbo
Enter choice [1-4]: ]])
      if models[choice] then
        current_model = models[choice]
        print("✅ Model set to: " .. current_model)
      else
        print("❌ Invalid choice. Keeping model: " .. current_model)
      end
    end

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
            },
            schema = {
              model = {
                default = function()
                  return current_model
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
      extensions = {
        mcphub = {
          callback = "mcphub.extensions.codecompanion",
          opts = {
            show_results_in_chat = true, -- Show MCP results in chat
            make_vars = true, -- Convert resources to #variables
            make_slash_commands = true, -- Add prompts as /slash commands
          },
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
    keymap("n", "<leader>im", function()
      choose_model()
    end, { desc = "📦 Choose OpenAI model" })
  end,
}
