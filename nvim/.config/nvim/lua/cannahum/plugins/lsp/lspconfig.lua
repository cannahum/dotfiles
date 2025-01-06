local pid = vim.fn.getpid()
local omnisharp_bin = vim.fn.stdpath("data") .. "/mason/bin/omnisharp"

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    -- import lspconfig plugin
    local lspconfig = require("lspconfig")

    -- import mason_lspconfig plugin
    local mason_lspconfig = require("mason-lspconfig")

    -- import cmp-nvim-lsp plugin
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- for conciseness

    vim.filetype.add({ extension = { templ = "templ" } })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        -- Buffer local mappings.
        -- See `:help vim.lsp.*` for documentation on any of the below functions
        local opts = { buffer = ev.buf, silent = true }

        -- set keybinds
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
      end,
    })

    -- used to enable autocompletion (assign to every lsp server config)
    local capabilities = cmp_nvim_lsp.default_capabilities()

    -- Change the Diagnostic symbols in the sign column (gutter)
    -- (not in youtube nvim video)
    local signs = { Error = " ", Warn = " ", Hint = "󰠠 ", Info = " " }
    for type, icon in pairs(signs) do
      local hl = "DiagnosticSign" .. type
      vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
    end

    mason_lspconfig.setup_handlers({
      -- default handler for installed servers
      function(server_name)
        lspconfig[server_name].setup({
          capabilities = capabilities,
        })
      end,
      ["omnisharp"] = function()
        lspconfig["omnisharp"].setup({
          cmd = { omnisharp_bin, "--languageserver", "--hostPID", tostring(pid) },
          root_dir = lspconfig.util.root_pattern("*.csproj", "*.sln"),
          capabilities = capabilities,
          enable_roslyn_analysers = true,
          enable_import_completion = true,
          organize_imports_on_format = true,
          enable_decompilation_support = true,
          filetypes = { "cs", "vb", "csproj", "sln", "slnx", "props", "csx", "targets" },
          on_attach = function(client, bufnr)
            -- require("omnisharp_extended").on_attach(client, bufnr)
            local opts = { noremap = false, silent = true }
            opts.desc = "Show LSP references"
            vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", "<Cmd>lua vim.lsp.buf.references()<CR>", opts) -- show definition, references

            opts.desc = "Go to definitions"
            vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts) -- go to definition

            opts.desc = "Show LSP declarations"
            vim.api.nvim_buf_set_keymap(
              bufnr,
              "n",
              "gD",
              '<Cmd>lua require("omnisharp_extended").telescope_lsp_definitions()<CR>',
              opts
            ) -- show lsp declaration

            opts.desc = "Show LSP implementations"
            vim.api.nvim_buf_set_keymap(bufnr, "n", "gi", "<Cmd>lua vim.lsp.buf.implementation()<CR>", opts) -- show lsp implementations

            opts.desc = "Show LSP type definitions"
            keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions
          end,
        })
      end,
      ["gopls"] = function()
        lspconfig["gopls"].setup({
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            local format_sync_grp = vim.api.nvim_create_augroup("goimports", {})
            vim.api.nvim_create_autocmd("BufWritePre", {
              pattern = "*.go",
              callback = function()
                require("go.format").gofmt() -- gofmt only
                require("go.format").goimports() -- goimports + gofmt
              end,
              group = format_sync_grp,
            })
          end,
        })
      end,
      ["templ"] = function()
        lspconfig["templ"].setup({
          -- on_attach = function(client, bufnr)
          --   vim.api.nvim_create_autocmd({ "BufWritePre" }, {
          --     pattern = { "*.templ" },
          --     callback = vim.lsp.buf.format,
          --   })
          -- end,
          on_attach = on_attach,
          capabilities = capabilities,
        })
      end,
      ["tailwindcss"] = function()
        lspconfig["tailwindcss"].setup({
          capabilities = capabilities,
          filetypes = { "templ", "astro", "javascript", "typescript", "react", "svelte" },
          init_options = { userLanguages = { templ = "html" } },
        })
      end,
      ["html"] = function()
        lspconfig["html"].setup({
          on_attach = on_attach,
          capabilities = capabilities,
          filetypes = { "html", "templ" },
          -- on_attach = function(client, bufnr)
          --   vim.api.nvim_create_autocmd({ "BufWritePre" }, {
          --     pattern = { "*.templ" },
          --     callback = vim.lsp.buf.format,
          --   })
          -- end,
        })
      end,
      ["htmx"] = function()
        lspconfig["htmx"].setup({
          on_attach = on_attach,
          capabilities = capabilities,
          filetypes = { "html", "templ" },
        })
      end,
      ["svelte"] = function()
        -- configure svelte server
        lspconfig["svelte"].setup({
          capabilities = capabilities,
          on_attach = function(client, bufnr)
            vim.api.nvim_create_autocmd("BufWritePost", {
              pattern = { "*.js", "*.ts" },
              callback = function(ctx)
                -- Here use ctx.match instead of ctx.file
                client.notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
              end,
            })
          end,
        })
      end,
      ["graphql"] = function()
        -- configure graphql language server
        lspconfig["graphql"].setup({
          capabilities = capabilities,
          filetypes = { "graphql", "gql", "svelte", "typescriptreact", "javascriptreact" },
        })
      end,
      ["emmet_ls"] = function()
        -- configure emmet language server
        lspconfig["emmet_ls"].setup({
          capabilities = capabilities,
          filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
        })
      end,
      ["lua_ls"] = function()
        -- configure lua server (with special settings)
        lspconfig["lua_ls"].setup({
          capabilities = capabilities,
          settings = {
            Lua = {
              -- make the language server recognize "vim" global
              diagnostics = {
                globals = { "vim" },
              },
              completion = {
                callSnippet = "Replace",
              },
            },
          },
        })
      end,
      ["kotlin_language_server"] = function()
        lspconfig["kotlin_language_server"].setup({
          capabilities = capabilities,
          on_attach = on_attach,
          filetypes = { "kt", "kts", "kotlin" },
        })
      end,
    })
  end,
}