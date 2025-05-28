return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    adapters = {
      openai = function()
        return require("codecompanion.adapters").extend("openai", {
          opts = {
            stream = true,
          },
          env = {
            api_key = os.getenv("OPENAI_API_TOKEN"),
          },
          schema = {
            model = {
              default = function()
                return "gpt-4.1"
              end,
            },
          },
        })
      end,
      copilot = function()
        return require("codecompanion.adapters").extend("copilot", {
          schema = {
            model = {
              default = "gpt-4.1",
            },
          },
        })
      end,
    },
  },
  config = function(_, _)
    local cc = require("codecompanion")
    cc.setup({
      strategies = {
        chat = {
          adapter = "copilot",
        },
        inline = {
          adapter = "copilot",
        },
      },
    })
    local keymap = vim.keymap.set
    keymap("n", "<leader>ii", function()
      cc.inline({})
    end, { desc = "Trigger CodeCompanion" })
    keymap("n", "<leader>ic", function()
      cc.chat()
    end, { desc = "Trigger CodeCompanion Chat" })
    keymap("n", "<leader>it", function()
      cc.toggle()
    end, { desc = "Toggle CodeCompanion" })
  end,
}
