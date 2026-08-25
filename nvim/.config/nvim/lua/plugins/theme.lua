-- On Omarchy, this file's content doesn't matter: bin/bootstrap-nvim's
-- link_omarchy_theme re-symlinks it straight to Omarchy's own theme file
-- at install time -- see that function for the full mechanism. Off
-- Omarchy (e.g. the Mac), that step is a no-op, so this plain stow
-- symlink is what actually loads -- contributing no theme opinion.
-- all-themes.lua already makes every theme available regardless of
-- platform; without Omarchy driving it, switch manually with
-- :colorscheme <name>.
return {}
