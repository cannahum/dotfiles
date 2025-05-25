return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  config = function()
    -- import mason
    local mason = require("mason")

    -- import mason-lspconfig
    local mason_lspconfig = require("mason-lspconfig")

    local mason_tool_installer = require("mason-tool-installer")

    -- enable mason and configure icons
    mason.setup({
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
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
    mason_tool_installer.setup({
      ensure_installed = {
        "prettier", -- prettier formatter
        "stylua", -- lua formatter
        "isort", -- python formatter
        "black", -- python formatter
        "pylint",
        "eslint_d",
        "golangci-lint",
        "csharpier",
        "ktlint",
        "sql-formatter",
      },
    })
  end,
}
