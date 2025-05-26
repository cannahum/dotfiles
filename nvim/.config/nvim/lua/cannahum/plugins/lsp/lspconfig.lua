return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  opts = {
    setup = {
      ts_ls = function()
        return true -- tells LazyVim to skip this server
      end,
    },
  },
  config = function()
    local lspconfig = require("lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")
    local capabilities = cmp_nvim_lsp.default_capabilities()
    -- Lua
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          runtime = {
            -- Tell the LSP you're using Neovim's Lua
            version = "LuaJIT",
          },
          diagnostics = {
            -- Tell the LSP that `vim` is a global variable
            globals = { "vim" },
          },
          workspace = {
            -- Make the server aware of Neovim runtime files
            library = vim.api.nvim_get_runtime_file("", true),
            checkThirdParty = false,
          },
          completion = {
            callSnippet = "Replace",
          },
          telemetry = {
            enable = false,
          },
        },
      },
    })
    -- Go
    lspconfig.gopls.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*.go",
          callback = function()
            require("go.format").gofmt()
            require("go.format").goimports()
          end,
          group = format_sync_grp,
        })
      end,
    })
    -- Templ
    lspconfig.templ.setup({
      capabilities = capabilities,
      on_attach = on_attach,
    })
    -- Tailwind CSS
    lspconfig.tailwindcss.setup({
      capabilities = capabilities,
      filetypes = { "templ", "astro", "javascript", "typescript", "react", "svelte" },
      init_options = { userLanguages = { templ = "html" } },
    })
    -- HTML
    lspconfig.html.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" },
    })
    -- HTMX
    lspconfig.htmx.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "html", "templ" },
    })
    -- Svelte
    lspconfig.svelte.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        vim.api.nvim_create_autocmd("BufWritePost", {
          pattern = { "*.js", "*.ts" },
          callback = function(ctx)
            client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
          end,
        })
      end,
    })
    -- GraphQL
    lspconfig.graphql.setup({
      capabilities = capabilities,
      filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
    })
    -- Emmet
    lspconfig.emmet_ls.setup({
      capabilities = capabilities,
      filetypes = {
        "html",
        "typescriptreact",
        "javascriptreact",
        "css",
        "sass",
        "scss",
        "less",
        "svelte",
      },
    })
    -- Kotlin
    lspconfig.kotlin_language_server.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      filetypes = { "kt", "kts", "kotlin" },
    })
    -- Marksman
    lspconfig.marksman.setup({
      capabilities = capabilities,
    })
    -- Zig
    lspconfig.zls.setup({
      capabilities = capabilities,
      cmd = { vim.fn.stdpath("data") .. "/mason/bin/zls" },
      on_attach = function(client, bufnr)
        client.server_capabilities.documentFormattingProvider = true
        client.server_capabilities.documentRangeFormattingProvider = true
        vim.diagnostic.config({ virtual_text = true })
      end,
    })
    -- TypeScript
    lspconfig.tsserver.setup({
      capabilities = capabilities,
      on_attach = function(client, bufnr)
        -- Add custom keymaps for tsserver, if needed
        local opts = { buffer = bufnr, silent = true }

        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

        -- Optionally, disable formatting if you prefer to use another tool
        client.server_capabilities.documentFormattingProvider = false
      end,
    })
  end,
}
