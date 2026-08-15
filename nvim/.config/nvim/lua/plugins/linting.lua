return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local biome = require("utils.biome")
    local use_biome = biome.has_biome_config()

    lint.linters.biome = {
      cmd = "biome",
      stdin = false,
      args = { "check", "--formatter", "json", "$FILENAME" },
      stream = "stdout",
      ignore_exitcode = true,
      parser = require("lint.parser").from_errorformat("%f:%l:%c %trror %m", {
        source = "biome",
        severity = vim.diagnostic.severity.ERROR,
      }),
    }

    -- js/ts/jsx/tsx/svelte diagnostics come from the eslint LSP when biome isn't
    -- in play; nvim-lint only needs to step in for biome projects (or python).
    local js_linters = use_biome and { "biome" } or {}
    lint.linters_by_ft = {
      javascript = js_linters,
      typescript = js_linters,
      javascriptreact = js_linters,
      typescriptreact = js_linters,
      svelte = js_linters,
      python = { "pylint" },
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>l", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })
  end,
}
