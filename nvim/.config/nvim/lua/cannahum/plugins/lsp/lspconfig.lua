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

-- ATTEMPT 5 based on 4
-- Kotlin LSP Configuration
local util = require("lspconfig.util")
local active_clients = {} -- Track clients by root_dir to avoid duplicates

vim.api.nvim_create_autocmd("FileType", {
  pattern = "kotlin",
  callback = function(ev)
    local bufname = vim.api.nvim_buf_get_name(ev.buf)

    -- Find the nearest Gradle project root
    local root =
      util.root_pattern("settings.gradle.kts", "settings.gradle", "build.gradle.kts", "build.gradle")(bufname)

    if not root then
      root = vim.fn.getcwd()
    end

    -- Check if we already have a client for this root
    if active_clients[root] then
      -- Client exists, just attach this buffer to it
      vim.lsp.buf_attach_client(ev.buf, active_clients[root])
      return
    end

    -- Start new client for this root
    local client_id = vim.lsp.start({
      name = "kotlin_lsp",
      cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp", "--stdio" },
      root_dir = root,
    })

    if client_id then
      active_clients[root] = client_id
    end
  end,
})

-- Clean up tracking when clients stop
vim.api.nvim_create_autocmd("LspDetach", {
  callback = function(args)
    for root, client_id in pairs(active_clients) do
      if client_id == args.data.client_id then
        active_clients[root] = nil
        break
      end
    end
  end,
})
-- ATTEMPT 4 - worked!
-- vim.lsp.config("kotlin_lsp", {
--   cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp", "--stdio" },
--   filetypes = { "kotlin" },
--   root_dir = vim.fn.getcwd, -- Just use current working directory
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = "kotlin",
--   callback = function()
--     vim.lsp.start({
--       name = "kotlin_lsp",
--       cmd = { vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp", "--stdio" },
--       root_dir = vim.fn.getcwd(),
--     })
--   end,
-- })
-- ATTEMPT 3
-- KOTLIN LSP WITH LOGGING
-- vim.notify("=== LOADING KOTLIN CONFIG ===", vim.log.levels.INFO)
--
-- local util = require("lspconfig.util")
-- local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp"
-- vim.notify("mason_bin set to: " .. mason_bin, vim.log.levels.INFO)
--
-- local function has_any(dir, names)
--   vim.notify("has_any called for dir: " .. dir, vim.log.levels.DEBUG)
--   for _, n in ipairs(names) do
--     if util.path.exists(util.path.join(dir, n)) then
--       vim.notify("Found file: " .. n, vim.log.levels.DEBUG)
--       return true
--     end
--   end
--   return false
-- end
--
-- local gradle_files = {
--   "settings.gradle.kts",
--   "settings.gradle",
--   "build.gradle.kts",
--   "build.gradle",
-- }
--
-- vim.notify("=== CALLING vim.lsp.config for kotlin_lsp ===", vim.log.levels.INFO)
-- vim.lsp.config("kotlin_lsp", {
--   cmd = { mason_bin, "--stdio" },
--   filetypes = { "kotlin" },
--   single_file_support = true,
--   root_dir = function(fname)
--     vim.notify("root_dir called with fname: " .. tostring(fname), vim.log.levels.INFO)
--
--     if type(fname) == "number" then
--       fname = vim.api.nvim_buf_get_name(fname)
--       vim.notify("fname was number, converted to: " .. fname, vim.log.levels.INFO)
--     end
--
--     local root = util.search_ancestors(fname, function(path)
--       if has_any(path, gradle_files) then
--         return path
--       end
--     end)
--
--     if not root and fname ~= "" then
--       root = vim.fn.fnamemodify(fname, ":h")
--       vim.notify("Using fallback root: " .. root, vim.log.levels.INFO)
--     end
--
--     local final_root = root or vim.fn.getcwd()
--     vim.notify("Final root_dir: " .. final_root, vim.log.levels.INFO)
--     return final_root
--   end,
--   on_attach = function(client, bufnr)
--     vim.notify(
--       "=== KOTLIN LSP ON_ATTACH CALLED === client: " .. client.name .. " bufnr: " .. bufnr,
--       vim.log.levels.WARN
--     )
--     default_on_attach(client, bufnr)
--   end,
--   capabilities = common_capabilities,
-- })
-- vim.notify("=== vim.lsp.config DONE ===", vim.log.levels.INFO)
--
-- vim.notify("=== CREATING AUTOCMD ===", vim.log.levels.INFO)
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "kotlin" },
--   callback = function(ev)
--     vim.notify(
--       "=== AUTOCMD FIRED === buffer: " .. ev.buf .. " filetype: " .. vim.bo[ev.buf].filetype,
--       vim.log.levels.WARN
--     )
--
--     if vim.fn.executable(mason_bin) == 0 then
--       vim.notify("kotlin-lsp not executable at " .. mason_bin, vim.log.levels.ERROR)
--       return
--     end
--
--     vim.notify("About to call vim.lsp.enable", vim.log.levels.WARN)
--     vim.lsp.enable("kotlin_lsp")
--     vim.notify("vim.lsp.enable returned", vim.log.levels.WARN)
--   end,
-- })
-- vim.notify("=== AUTOCMD CREATED ===", vim.log.levels.INFO)

-- ATTEMPT 2
-- local util = require("lspconfig.util")
-- local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp"
-- local function has_any(dir, names)
--   for _, n in ipairs(names) do
--     if util.path.exists(util.path.join(dir, n)) then
--       return true
--     end
--   end
--   return false
-- end
-- local gradle_files = {
--   "settings.gradle.kts",
--   "settings.gradle",
--   "build.gradle.kts",
--   "build.gradle",
-- }
-- vim.lsp.config("kotlin_lsp", {
--   cmd = { mason_bin, "--stdio" },
--   filetypes = { "kotlin" },
--   single_file_support = true,
--   root_dir = function(fname)
--     if type(fname) == "number" then
--       fname = vim.api.nvim_buf_get_name(fname)
--     end
--     local root = util.search_ancestors(fname, function(path)
--       if has_any(path, gradle_files) then
--         return path
--       end
--     end)
--     if not root and fname ~= "" then
--       root = vim.fn.fnamemodify(fname, ":h")
--     end
--     return root or vim.fn.getcwd()
--   end,
--   on_attach = default_on_attach,
--   capabilities = common_capabilities,
-- })
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "kotlin" },
--   callback = function(ev)
--     if vim.fn.executable(mason_bin) == 0 then
--       vim.notify("kotlin-lsp not executable at " .. mason_bin, vim.log.levels.ERROR)
--       return
--     end
--     vim.lsp.enable("kotlin_lsp")
--   end,
-- })
--
-- ATTEMPT 1
-- local util = require("lspconfig.util")
-- local mason_bin = vim.fn.stdpath("data") .. "/mason/bin/kotlin-lsp"
--
-- -- helper: does PATH contain any of these files?
-- local function has_any(dir, names)
--   for _, n in ipairs(names) do
--     if util.path.exists(util.path.join(dir, n)) then
--       return true
--     end
--   end
--   return false -- explicit return
-- end
--
-- local gradle_files = {
--   "settings.gradle.kts",
--   "settings.gradle",
--   "build.gradle.kts",
--   "build.gradle",
-- }
--
-- vim.lsp.config("kotlin_lsp", {
--   cmd = { mason_bin, "--stdio" }, -- Don't forget this!
--   filetypes = { "kotlin" },
--   single_file_support = true,
--   root_dir = function(fname)
--     -- Ensure fname is actually a filename string
--     if type(fname) == "number" then
--       fname = vim.api.nvim_buf_get_name(fname)
--     end
--     local root = util.search_ancestors(fname, function(path)
--       if has_any(path, gradle_files) then
--         return path
--       end
--     end)
--     -- Fallback to the directory containing the file
--     if not root and fname ~= "" then
--       root = vim.fn.fnamemodify(fname, ":h")
--     end
--     return root or vim.fn.getcwd()
--   end,
--   on_attach = default_on_attach,
--   capabilities = common_capabilities,
-- })
--
-- -- Autostart for Kotlin buffers
-- vim.api.nvim_create_autocmd("FileType", {
--   pattern = { "kotlin" },
--   callback = function(ev)
--     -- Guard: warn early if the cmd isn't executable
--     if vim.fn.executable(mason_bin) == 0 then
--       vim.notify("kotlin-lsp not executable at " .. mason_bin, vim.log.levels.ERROR)
--       return
--     end
--
--     vim.notify("Attempting to enable kotlin_lsp for buffer " .. ev.buf, vim.log.levels.INFO)
--     vim.lsp.enable("kotlin_lsp")
--
--     -- Debug: check if client attached after a brief delay
--     vim.defer_fn(function()
--       local clients = vim.lsp.get_clients({ bufnr = ev.buf, name = "kotlin_lsp" })
--       if #clients == 0 then
--         vim.notify("No kotlin_lsp clients attached to buffer!", vim.log.levels.WARN)
--       else
--         vim.notify("Found " .. #clients .. " kotlin_lsp client(s)", vim.log.levels.INFO)
--       end
--     end, 1000)
--   end,
-- })
-- ATTEMPT 0
-- vim.lsp.config("kotlin_lsp", {
--   on_attach = default_on_attach,
--   capabilities = common_capabilities,
--   filetypes = { "kotlin", "kotlin-script", "kts" }, -- "kotlin" covers .kt too
--   root_dir = function(fname)
--     -- climb up; stop if we hit a gradle root
--     return util.search_ancestors(fname, function(path)
--       if has_any(path, gradle_files) then
--         return path
--       end
--     end)
--   end,
--   single_file_support = true,
-- })
--
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
