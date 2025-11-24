return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")
    local biome = require("cannahum.utils.biome")
    local use_biome = biome.has_biome_config()

    -- helper to keep JS/TS lists tidy
    local function js_like()
      if use_biome then
        return { "biome" } -- biome handles formatting + organize imports
      else
        return { "prettierd", "prettier" } -- try prettierd, fall back to prettier
      end
    end

    conform.setup({
      formatters_by_ft = {
        javascript = js_like(),
        typescript = js_like(),
        javascriptreact = js_like(),
        typescriptreact = js_like(),
        svelte = js_like(),
        -- if you want biome for json/markdown too, add them here:
        -- json           = js_like(),
        -- markdown       = js_like(),
        cs = { "csharpier" },
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
        ["*"] = { "trim_newlines", "trim_whitespace" },
      },

      formatters = {
        biome = {
          command = "biome",
          args = { "check", "--write", "--stdin-file-path", "$FILENAME" },
          stdin = true,
          require_cwd = true, -- only runs if biome config exists
        },
        ["sql-formatter"] = {
          command = "sql-formatter",
          args = { "--language", "postgresql" },
          stdin = true,
        },
      },

      -- IMPORTANT: replace old nested {} behavior with stop_after_first
      format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
          stop_after_first = true, -- ← key change
        }
      end,
    })

    -- manual format keymap (match behavior on save)
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
        stop_after_first = true, -- ← key change
        -- If you want to force a list here, keep it flat, e.g.:
        -- formatters = js_like(),
      })
    end, { desc = "Format file or range (in visual mode)" })

    vim.api.nvim_create_user_command("CodeAutoformatSave", function(args)
      if args.bang then
        local curr = vim.b.disable_autoformat or false
        vim.b.disable_autoformat = not curr
        print(vim.b.disable_autoformat and "Buffer autoformat on save disabled" or "Buffer autoformat on save enabled")
      else
        local curr = vim.g.disable_autoformat or false
        vim.g.disable_autoformat = not curr
        print(vim.g.disable_autoformat and "Global autoformat on save disabled" or "Global autoformat on save enabled")
      end
    end, { bang = true, desc = "Toggle autoformat-on-save (use ! for buffer only)" })

    vim.keymap.set("n", "<leader>cas", "<cmd>CodeAutoformatSave<cr>", { desc = "Toggle autoformat on save" })
  end,
}
