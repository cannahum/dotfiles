return {
  "lukas-reineke/headlines.nvim",
  opts = function()
    local opts = {}
    opts.markdown = {
      codeblock_highlight = "CodeBlock",
      dash_highlight = "Dash",
    }
    return opts
  end,
}
