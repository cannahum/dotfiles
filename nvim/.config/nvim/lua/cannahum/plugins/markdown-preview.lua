return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview", "MarkdownPreviewStop" },
  build = "cd app && npm install",
  keys = {
    { "<leader>mp", "<cmd>MarkdownPreview<cr>", desc = "Preview Markdown" },
    { "<leader>ms", "<cmd>MarkdownPreviewStop<cr>", desc = "Stop Markdown Preview" },
  },
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
  config = function()
    vim.g.mkdp_preview_options = {
      mermaid = {
        theme = "default",
      },
    }
  end,
}
