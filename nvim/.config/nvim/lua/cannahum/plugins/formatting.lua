return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        svelte = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        graphql = { "prettier" },
        liquid = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        kotlin = { "ktlint" },
        templ = { "templ" },
        sql = { "sql-formatter" },
      },
      formatters = {
        ["sql-formatter"] = {
          command = "sql-formatter",
          args = { "--language", "postgresql" },
          stdin = true,
        },
      },
      format_on_save = function(bufnr)
        -- Disable with a global or buffer-local variable
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end,
    })

    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (in visual mode)" })

    vim.api.nvim_create_user_command("CodeAutoformatSave", function(args)
      if args.bang then
        local curr = vim.b.disable_autoformat or false
        vim.b.disable_autoformat = not curr
        if vim.b.disable_autoformat then
          print("Buffer autoformat on save disabled")
        else
          print("Buffer autoformat on save enabled")
        end
      else
        local curr = vim.g.disable_autoformat or false
        vim.g.disable_autoformat = not curr
        if vim.g.disable_autoformat then
          print("Global autoformat on save disabled")
        else
          print("Global autoformat on save enabled")
        end
      end
    end, {
      bang = true,
      desc = "Toggle autoformat-on-save (use ! for buffer only)",
    })

    vim.keymap.set("n", "<leader>cas", "<cmd>CodeAutoformatSave<cr>", { desc = "Toggle autoformat on save" })
  end,
}
