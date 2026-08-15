return {
  "mfussenegger/nvim-lint",
  opts = function(_, opts)
    local biome = require("utils.biome")
    local use_biome = biome.has_biome_config()

    -- js/ts/jsx/tsx/svelte diagnostics come from the eslint LSP when biome isn't
    -- in play; nvim-lint only needs to step in for biome projects (or python).
    local js_linters = use_biome and { "biome" } or {}

    return vim.tbl_deep_extend("force", opts, {
      linters_by_ft = {
        javascript = js_linters,
        typescript = js_linters,
        javascriptreact = js_linters,
        typescriptreact = js_linters,
        svelte = js_linters,
        python = { "pylint" },
      },
      linters = {
        biome = {
          cmd = "biome",
          stdin = false,
          args = { "check", "--formatter", "json", "$FILENAME" },
          stream = "stdout",
          ignore_exitcode = true,
          parser = require("lint.parser").from_errorformat("%f:%l:%c %trror %m", {
            source = "biome",
            severity = vim.diagnostic.severity.ERROR,
          }),
        },
      },
    })
  end,
  keys = {
    {
      "<leader>l",
      function()
        require("lint").try_lint()
      end,
      desc = "Trigger linting for current file",
    },
  },
}
