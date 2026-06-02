return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    require("nvim-treesitter").setup({
      highlight = { enable = true },
      indent = { enable = true },
      ensure_installed = {
        "json",
        "javascript",
        "typescript",
        "tsx",
        "yaml",
        "html",
        "css",
        "prisma",
        "markdown",
        "markdown_inline",
        "mermaid",
        "svelte",
        "graphql",
        "bash",
        "lua",
        "vim",
        "dockerfile",
        "gitignore",
        "query",
        "vimdoc",
        "c",
        "go",
        "gomod",
        "java",
        "python",
        "templ",
        "c_sharp",
        "kotlin",
        "zig",
        "proto",
        "sql",
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          scope_incremental = false,
          node_decremental = "<bs>",
        },
      },
    })

    require("nvim-ts-autotag").setup()

    -- telescope calls nvim-treesitter APIs removed in 0.12; shim them back
    local parsers = require("nvim-treesitter.parsers")
    if not parsers.ft_to_lang then
      parsers.ft_to_lang = function(ft)
        return vim.treesitter.language.get_lang(ft) or ft
      end
    end
    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if ok and not configs.is_enabled then
      configs.is_enabled = function(_, lang, bufnr)
        local ok2 = pcall(vim.treesitter.get_parser, bufnr or 0, lang)
        return ok2
      end
    end
  end,
}
