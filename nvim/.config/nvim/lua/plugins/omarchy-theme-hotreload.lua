return {
	{
		name = "theme-hotreload",
		dir = vim.fn.stdpath("config"),
		lazy = false,
		priority = 1000,
		config = function()
			local transparency_file = vim.fn.stdpath("config") .. "/plugin/after/transparency.lua"

			-- WIP: this poller duplicates lazy.nvim's own built-in change
			-- detector (which already polls files under lua/plugins/ every 2s
			-- and fires this same LazyReload event) -- next step is to remove
			-- it and instead symlink theme.lua straight to Omarchy's
			-- neovim.lua at bootstrap time, the way vanilla omarchy-nvim does,
			-- so lazy's existing poller covers this with no extra code.
			--
			-- theme.lua reads the active theme via dofile() (not require), so it
			-- degrades to {} off Omarchy instead of erroring on a missing symlink
			-- (see theme.lua's header). That indirection means lazy.nvim's own
			-- change-detector -- which only watches the mtime of files it
			-- requires under lua/plugins/ -- never sees theme.lua's dofile'd
			-- target change, so it never fires the LazyReload event this autocmd
			-- waits for. Omarchy swaps themes by rm -rf'ing and mv'ing a whole
			-- directory into place (see omarchy-theme-set), which also
			-- invalidates any inotify-style watch on a file inside it, so poll
			-- by stat -- like lazy.nvim itself does -- instead of watching it.
			-- Off Omarchy this file never exists, so the poll simply never starts.
			local omarchy_theme_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
			if vim.fn.filereadable(omarchy_theme_file) == 1 then
				local last_stat = vim.uv.fs_stat(omarchy_theme_file)
				local timer = vim.uv.new_timer()
				timer:start(2000, 2000, function()
					local stat = vim.uv.fs_stat(omarchy_theme_file)
					if stat and (not last_stat or stat.mtime.sec ~= last_stat.mtime.sec or stat.size ~= last_stat.size) then
						last_stat = stat
						vim.schedule(function()
							vim.api.nvim_exec_autocmds("User", { pattern = "LazyReload", modeline = false })
						end)
					end
				end)
			end

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyReload",
				callback = function()
					-- Unload the theme module
					package.loaded["plugins.theme"] = nil

					vim.schedule(function()
						local ok, theme_spec = pcall(require, "plugins.theme")
						if not ok then
							return
						end

						-- Find the theme plugin and unload it
						local theme_plugin_name = nil
						for _, spec in ipairs(theme_spec) do
							if spec[1] and spec[1] ~= "LazyVim/LazyVim" then
								theme_plugin_name = spec.name or spec[1]
								break
							end
						end

						-- Clear all highlight groups before applying new theme
						vim.cmd("highlight clear")
						if vim.fn.exists("syntax_on") then
							vim.cmd("syntax reset")
						end

						-- Reset background to default so colorscheme can set it properly (light themes will set to light)
						vim.o.background = "dark"

						-- Unload theme plugin modules to force full reload
						if theme_plugin_name then
							local plugin = require("lazy.core.config").plugins[theme_plugin_name]
							if plugin then
								-- Unload all lua modules from the plugin directory
								local plugin_dir = plugin.dir .. "/lua"
								require("lazy.core.util").walkmods(plugin_dir, function(modname)
									package.loaded[modname] = nil
									package.preload[modname] = nil
								end)
							end
						end

						-- Find and apply the new colorscheme
						for _, spec in ipairs(theme_spec) do
							if spec[1] == "LazyVim/LazyVim" and spec.opts and spec.opts.colorscheme then
								local colorscheme = spec.opts.colorscheme

								-- Load the colorscheme plugin. If it's already loaded (old and new
								-- theme sharing the same plugin, e.g. generic themes on aether.nvim),
								-- lazy won't rerun setup() on a spec reload and keeps the old
								-- resolved opts in the plugin's property cache, so fully reload it
								-- to reapply setup() with the new theme's opts.
								local theme_plugin = theme_plugin_name and require("lazy.core.config").plugins[theme_plugin_name]
								if theme_plugin and theme_plugin._.loaded then
									require("lazy.core.loader").reload(theme_plugin)
								else
									require("lazy.core.loader").colorscheme(colorscheme)
								end

								vim.defer_fn(function()
									-- Apply the colorscheme (it will set background itself)
									pcall(vim.cmd.colorscheme, colorscheme)

									-- Force redraw to update all UI elements
									vim.cmd("redraw!")

									-- Reload transparency settings
									if vim.fn.filereadable(transparency_file) == 1 then
										vim.defer_fn(function()
											vim.cmd.source(transparency_file)

											-- Trigger UI updates for various plugins
											vim.api.nvim_exec_autocmds("ColorScheme", { modeline = false })
											vim.api.nvim_exec_autocmds("VimEnter", { modeline = false })

											-- Final redraw
											vim.cmd("redraw!")
										end, 5)
									end
								end, 5)

								break
							end
						end
					end)
				end,
			})
		end,
	},
}
