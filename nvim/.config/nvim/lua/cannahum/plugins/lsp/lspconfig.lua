-- Shared on_attach function for most servers
local omnisharp_extended = require("omnisharp_extended")
local function default_on_attach(client, bufnr)
  print(client.name .. " attached to buffer " .. bufnr)
  local opts = { buffer = bufnr, silent = true }
  if client.name == "omnisharp" then
    vim.keymap.set("n", "gd", omnisharp_extended.lsp_definition, opts)
    vim.keymap.set("n", "gr", omnisharp_extended.lsp_references, opts)
    vim.keymap.set("n", "gi", omnisharp_extended.lsp_implementation, opts)
  else
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
  end
end
local common_capabilities = require("cmp_nvim_lsp").default_capabilities()

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

-- Kotlin LSP Configuration - TRUE SINGLETON CLIENT AT MONOREPO ROOT
local util = require("lspconfig.util")
local kotlin_client_id = nil -- Only ONE client per neovim instance
local monorepo_root = nil -- Cache for monorpo root
-- Helper: find the OUTERMOST Gradle root
local function find_gradle_root(path)
  if monorepo_root then
    return monorepo_root
  end
  local last_root = nil
  local current = util.path.dirname(path)
  while current and #current > 1 do
    local settings = util.path.join(current, "settings.gradle.kts")
    local settings_alt = util.path.join(current, "settings.gradle")
    local build = util.path.join(current, "build.gradle.kts")
    local build_alt = util.path.join(current, "build.gradle")
    if
      vim.loop.fs_stat(settings)
      or vim.loop.fs_stat(settings_alt)
      or vim.loop.fs_stat(build)
      or vim.loop.fs_stat(build_alt)
    then
      last_root = current
    end
    current = util.path.dirname(current)
  end
  monorepo_root = last_root
  pcall(
    vim.notify,
    "monorepo_root set to " .. tostring(monorepo_root),
    vim.log.levels.INFO,
    { title = "find_gradle_root" }
  )
  return monorepo_root
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  callback = function(ev)
    -- Always use the cached monorepo root for all buffers
    local bufname = vim.api.nvim_buf_get_name(ev.buf)
    local root = find_gradle_root(bufname) or vim.fn.getcwd()
    -- Attach to singleton client if it exists and is valid
    if kotlin_client_id then
      local client = vim.lsp.get_client_by_id(kotlin_client_id)
      if client and client.config.root_dir == root then
        vim.lsp.buf_attach_client(ev.buf, kotlin_client_id)
        return
      elseif client == nil then
        kotlin_client_id = nil -- Client died, clear it
      end
    end
    -- give kotlin-lsp its own Gradle home to avoid global ~/.gradle locks
    local gradle_home = vim.fn.stdpath("data") .. "/kotlin-lsp-gradle-home"
    vim.fn.mkdir(gradle_home, "p")
    pcall(
      vim.notify,
      "starting singleton kotlin-lsp at " .. root,
      vim.log.levels.INFO,
      { title = "Kotlin FileType CB" }
    )
    -- start the lsp
    kotlin_client_id = vim.lsp.start({
      name = "kotlin_lsp",
      cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp", "--stdio" },
      root_dir = root,
      cmd_env = {
        GRADLE_USER_HOME = gradle_home,
        -- JAVA_HOME = "path/to/java17", -- uncomment if your default Java < 17
      },
    })
  end,
})

vim.lsp.config("omnisharp", {
  on_attach = default_on_attach,
  capabilities = common_capabilities,
})

vim.api.nvim_create_autocmd("VimLeavePre", {
  callback = function()
    if kotlin_client_id then
      local client = vim.lsp.get_client_by_id(kotlin_client_id)
      if client then
        client.stop()
      end
    end
  end,
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
        "kotlin_lsp",
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
