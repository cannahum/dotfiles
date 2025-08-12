-- Shared on_attach function for most servers
local function default_on_attach(client, bufnr)
  print(client.name .. " attached to buffer " .. bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
  vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
  vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
end
-- local common_capabilities = require("cmp_nvim_lsp").default_capabilities()
local common_capabilities = vim.lsp.protocol.make_client_capabilities()

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = "Replace" },
    },
  },
  on_attach = default_on_attach,
})

vim.lsp.config("ts_ls", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
})

vim.lsp.config("gopls", {
  on_attach = function(client, bufnr)
    default_on_attach(client, bufnr)
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

vim.lsp.config("templ", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
})

vim.lsp.config("tailwindcss", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
  filetypes = { "templ", "astro", "javascript", "typescript", "javascriptreact", "typescriptreact", "svelte" },
  init_options = { userLanguages = { templ = "html" } },
})

vim.lsp.config("html", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
  filetypes = { "html", "templ" },
})

vim.lsp.config("htmx", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
  filetypes = { "html", "templ", "svelte", "react" },
})

vim.lsp.config("zls", {
  cmd = { vim.fn.stdpath("data") .. "/mason/bin/zls" },
  on_attach = function(client, bufnr)
    default_on_attach(client, bufnr)
    client.server_capabilities.documentFormattingProvider = true
    client.server_capabilities.documentRangeFormattingProvider = true
    vim.diagnostic.config({ virtual_text = true })
  end,
})

vim.lsp.config("svelte", {
  on_attach = function(client, bufnr)
    default_on_attach(client, bufnr)
    -- Notify the svelte server of changes to JS/TS files
    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = { "*.js", "*.ts" },
      callback = function(ctx)
        client.notify("$/onDidChangeTsOrJsFile", { uri = vim.uri_from_bufnr(ctx.buf) })
      end,
    })
  end,
  capabilities = common_capabilities,
})

vim.lsp.config("graphql", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
  filetypes = { "graphql", "graphqls", "gql", "svelte", "typescriptreact", "javascriptreact" },
})

vim.lsp.config("emmet_ls", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
  filetypes = { "html", "typescriptreact", "javascriptreact", "css", "sass", "scss", "less", "svelte" },
})

local lspconfig = require("lspconfig")
local configs = require("lspconfig.configs")
if not configs.kotlin_lsp then
  configs.kotlin_lsp = {
    default_config = {
      cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp", "--stdio" },
      filetypes = { "kt", "kts", "kotlin" },
      root_dir = lspconfig.util.root_pattern(
        "settings.gradle.kts",
        "settings.gradle",
        "pom.xml",
        "build.gradle.kts",
        "build.gradle",
        ".git"
      ),
      single_file_support = true,
    },
  }
end
lspconfig.kotlin_lsp.setup({
  on_attach = default_on_attach,
  capabilities = common_capabilities,
})

return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    { "antosha417/nvim-lsp-file-operations", config = true },
    { "folke/neodev.nvim", opts = {} },
  },
  config = function()
    local mason_lspconfig = require("mason-lspconfig")
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
    mason_lspconfig.setup({
      ensure_installed = {
        "cmake",
        "cssls",
        "docker_compose_language_service",
        "dockerls",
        "emmet_ls",
        "gopls",
        "graphql",
        "html",
        "htmx",
        "jsonls",
        "kotlin_language_server",
        "lua_ls",
        "marksman",
        "omnisharp",
        "prismals",
        "pyright",
        "rust_analyzer",
        "spectral",
        "sqlls",
        "svelte",
        "tailwindcss",
        "taplo",
        "templ",
        "terraformls",
        "ts_ls",
        "yamlls",
        "zls",
      },
    })
  end,
}
