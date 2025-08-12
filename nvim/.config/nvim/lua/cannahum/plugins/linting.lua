return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")
    local biome = require("cannahum.utils.biome")
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

    lint.linters_by_ft = {
      javascript = { use_biome and "biome" or "eslint_d" },
      typescript = { use_biome and "biome" or "eslint_d" },
      javascriptreact = { use_biome and "biome" or "eslint_d" },
      typescriptreact = { use_biome and "biome" or "eslint_d" },
      svelte = { use_biome and "biome" or "eslint_d" },
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
