return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local lualine = require("lualine")
    local lazy_status = require("lazy.status")

    lualine.setup({
      options = {
        theme = "auto", -- ✨ follow rose-pine dawn/night etc.
        globalstatus = true, -- single statusline (nice)
      },
      sections = {
        lualine_x = {
          {
            lazy_status.updates,
            cond = lazy_status.has_updates,
            color = { fg = "#ff9e64" },
          },
          { "encoding" },
          { "fileformat" },
          { "filetype" },
        },
      },
    })

    -- Refresh lualine when colorscheme changes (covers Omarchy flips)
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("LualineRefreshOnTheme", { clear = true }),
      callback = function()
        local ok, l = pcall(require, "lualine")
        if ok then
          pcall(l.setup, l.get_config())
        end
      end,
    })
  end,
}
