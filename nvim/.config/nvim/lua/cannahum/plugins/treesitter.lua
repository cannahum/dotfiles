return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    local ensure_installed = {
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
    }

    require("nvim-treesitter").setup()
    -- main-branch nvim-treesitter's setup() doesn't read ensure_installed at all;
    -- parsers must be installed explicitly. install() skips ones already present.
    require("nvim-treesitter").install(ensure_installed)

    require("nvim-ts-autotag").setup()

    -- main-branch nvim-treesitter no longer auto-starts highlighting from setup();
    -- it must be started per-buffer. See :h treesitter-highlight
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("cannahum-treesitter-highlight", { clear = true }),
      callback = function()
        pcall(vim.treesitter.start)
      end,
    })
  end,
}
