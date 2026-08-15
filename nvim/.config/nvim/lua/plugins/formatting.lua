return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    local biome = require("utils.biome")
    local use_biome = biome.has_biome_config()

    -- helper to keep JS/TS lists tidy
    local function js_like()
      if use_biome then
        return { "biome" } -- biome handles formatting + organize imports
      else
        return { "prettierd" }
      end
    end

    return vim.tbl_deep_extend("force", opts, {
      formatters_by_ft = {
        javascript = js_like(),
        typescript = js_like(),
        javascriptreact = js_like(),
        typescriptreact = js_like(),
        svelte = js_like(),
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
        -- jdtls handles formatting via LSP fallback (see default_format_opts below)
        java = { lsp_format = "first" },
        templ = { "templ" },
        sql = { "sql-formatter" },
        proto = { "buf" },
        swift = { "swift" },
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
        -- kotlin's formatter needs longer than LazyVim's 3s default_format_opts
        ktlint = {
          timeout_ms = 5000,
        },
      },
    })
  end,
}
