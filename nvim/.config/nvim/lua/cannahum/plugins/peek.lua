return {
  "toppair/peek.nvim",
  build = "deno task --quiet build:fast",
  keys = {
    { "<leader>mp", function() require("peek").open() end, desc = "Preview Markdown" },
    { "<leader>ms", function() require("peek").close() end, desc = "Stop Markdown Preview" },
  },
  ft = { "markdown" },
  opts = {
    theme = "dark",
    app = "browser",
  },
}
