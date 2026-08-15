-- Predeclare popular themes so Lazy can install/load them on demand.
return {
  { "neanias/everforest-nvim", name = "everforest", lazy = true },
  { "catppuccin/nvim", name = "catppuccin", lazy = true },
  { "folke/tokyonight.nvim", name = "tokyonight", lazy = true },
  { "rebelot/kanagawa.nvim", name = "kanagawa", lazy = true },
  { "EdenEast/nightfox.nvim", name = "nightfox", lazy = true },
  { "ellisonleao/gruvbox.nvim", name = "gruvbox", lazy = true },
  { "rose-pine/neovim", name = "rose-pine", lazy = true },
  { "kepano/flexoki-neovim", name = "flexoki", lazy = true },
  { "tahayvr/matteblack.nvim", name = "matte-black", lazy = true },
  { "ribru17/bamboo.nvim", name = "osaka-jade", lazy = true },
  { "loctvl842/monokai-pro.nvim", name = "ristretto", lazy = true },
  { "bjarneo/ethereal.nvim", name = "ethereal", lazy = true },
  { "bjarneo/hackerman.nvim", name = "hackerman", lazy = true, dependencies = { "bjarneo/aether.nvim" } },
  {
    "bjarneo/aether.nvim",
    name = "aether", -- Omarchy's "Ristretto" theme; previously only pulled in as
    -- hackerman's undeclared dependency, so omarchy-follow-theme.lua's
    -- Lazy.load({ plugins = { "aether" } }) never found a plugin by that
    -- name and `:colorscheme aether` failed with E185.
    lazy = true,
    priority = 1000,
    config = function()
      -- Omarchy's own theme/neovim.lua ships a full custom color palette for
      -- aether.nvim (LazyVim plugin-spec format). Read it directly instead
      -- of hardcoding a Ristretto-specific snapshot, so whichever Omarchy
      -- theme is active gets its real colors, not aether's generic default.
      local theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
      local colors
      if vim.fn.filereadable(theme_file) == 1 then
        local ok, spec = pcall(dofile, theme_file)
        if ok and type(spec) == "table" then
          for _, entry in ipairs(spec) do
            if entry[1] == "bjarneo/aether.nvim" and entry.opts and entry.opts.colors then
              colors = entry.opts.colors
              break
            end
          end
        end
      end
      require("aether").setup({ colors = colors or {} })
    end,
  },
  { "xero/miasma.nvim", name = "miasma", lazy = true },
  { "OldJobobo/retro-82.nvim", name = "retro-82", lazy = true },
  { "omacom-io/lumon.nvim", name = "lumon", lazy = true },
  { "bjarneo/vantablack.nvim", name = "vantablack", lazy = true },
  { "bjarneo/white.nvim", name = "white", lazy = true },
  { "ficcdaf/ashen.nvim", name = "ashen", lazy = true }, -- Omarchy's "Solitude" theme
}
