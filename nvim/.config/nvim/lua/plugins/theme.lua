-- On Omarchy this mirrors ~/.local/state/omarchy/current/theme/neovim.lua --
-- the file Omarchy itself writes/relinks on every `omarchy theme set`, in
-- LazyVim plugin-spec format (see all-themes.lua's header comment for why
-- the plugin name/branch there have to match what this generates).
--
-- Off Omarchy (e.g. the Mac) that path never exists, so this returns an
-- empty spec instead of erroring -- `{ import = "plugins" }` requires every
-- file under lua/plugins/, and a dangling symlink here would break startup
-- entirely, not just leave theme-following inert. all-themes.lua already
-- makes every theme available regardless of platform; without Omarchy
-- driving it, just switch manually with :colorscheme <name>.
local omarchy_theme = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(omarchy_theme) == 1 then
  return dofile(omarchy_theme)
end

return {}
