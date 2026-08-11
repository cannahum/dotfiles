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
        return { "prettierd" }
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
        -- jdtls handles formatting; run it before the "*" trim cleanup below
        -- (lsp_fallback=true elsewhere would never reach LSP here since the
        -- "*" wildcard always has a formatter available, defeating "fallback")
        java = { lsp_format = "first" },
        templ = { "templ" },
        sql = { "sql-formatter" },
        proto = { "buf" },
        swift = { "swift" },
        ["*"] = { "trim_newlines", "trim_whitespace" },
      },

      -- Global default: fall back to LSP formatting when no formatter is
      -- configured for a filetype. Set here (not per-call) so per-filetype
      -- overrides like java's lsp_format="first" above aren't clobbered.
      default_format_opts = {
        lsp_format = "fallback",
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
        local is_kotlin = vim.bo[bufnr].filetype == "kotlin"
        return {
          timeout_ms = is_kotlin and 5000 or 1000,
        }
      end,
    })

    -- manual format keymap (match behavior on save)
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      conform.format({
        async = false,
        timeout_ms = 1000,
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
