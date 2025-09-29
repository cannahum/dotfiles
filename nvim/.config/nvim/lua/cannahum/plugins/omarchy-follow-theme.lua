return {
  {
    "nvim-lua/plenary.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local uv = vim.uv or vim.loop
      local om_dir = vim.fn.expand("~/.config/omarchy/current")
      local theme_lua = vim.fn.expand(om_dir .. "/theme/neovim.lua")
      local bg_file = vim.fn.expand(om_dir .. "/background")

      if vim.fn.isdirectory(om_dir) == 0 then
        vim.notify("Omarchy not detected; watcher disabled", vim.log.levels.DEBUG, { title = "Omarchy" })
        return
      end

      local function slurp(path)
        local fd = uv.fs_open(path, "r", 438)
        if not fd then
          return nil
        end
        local st = uv.fs_fstat(fd)
        if not st then
          uv.fs_close(fd)
          return nil
        end
        local data = uv.fs_read(fd, st.size, 0)
        uv.fs_close(fd)
        return data
      end

      local function read_colorscheme()
        local data = slurp(theme_lua)
        if not data then
          return nil
        end
        local m = data:match('colorscheme%s*=%s*"([^"]+)"')
        if m then
          return m
        end
        m = data:match('vim%.cmd%.colorscheme%(%s*"([^"]+)"%s*%)')
          or data:match('vim%.cmd%(%s*"colorscheme%s+([^"]+)"%s*%)')
        return m
      end

      local function read_background()
        local b = slurp(bg_file)
        if not b then
          return nil
        end
        b = b:gsub("%s+", "")
        if b == "light" or b == "dark" then
          return b
        end
        return nil
      end

      -- Map colorscheme -> plugin name declared in omarchy-colorschemes.lua
      local known = {
        everforest = "everforest",
        catppuccin = "catppuccin",
        tokyonight = "tokyonight",
        kanagawa = "kanagawa",
        nightfox = "nightfox",
        gruvbox = "gruvbox",
        ["rose-pine"] = "rose-pine",
        dracula = "dracula",
        onedark = "onedark",
        nord = "nord",
      }

      local function ensure_and_apply(cs)
        local ok_lazy, Lazy = pcall(require, "lazy")
        if not ok_lazy then
          return
        end

        -- set background first (helps some themes)
        local bg = read_background()
        if bg then
          vim.o.background = bg
        end
        vim.o.termguicolors = true

        -- try to load the matching plugin by name (installs if missing, since it's in spec)
        local plugin_name = known[cs]
        if plugin_name then
          pcall(Lazy.load, { plugins = { plugin_name }, wait = true })
        end

        -- apply now, retry once if it fails (install might still be finishing)
        local function apply()
          local ok, err = pcall(vim.cmd.colorscheme, cs)
          if not ok then
            vim.defer_fn(function()
              local ok2, err2 = pcall(vim.cmd.colorscheme, cs)
              if not ok2 then
                vim.notify(
                  ("Failed to set colorscheme '%s': %s"):format(cs, tostring(err2)),
                  vim.log.levels.WARN,
                  { title = "Omarchy · Theme" }
                )
              else
                vim.notify(
                  ("Applied colorscheme '%s' after install"):format(cs),
                  vim.log.levels.INFO,
                  { title = "Omarchy · Theme" }
                )
              end
            end, 500)
          else
            vim.notify(("Applied colorscheme '%s'"):format(cs), vim.log.levels.INFO, { title = "Omarchy · Theme" })
          end
        end

        apply()
      end

      local last_cs = nil
      local function on_theme_change(tag)
        local cs = read_colorscheme() or (vim.g.colors_name or "unknown")
        if cs == last_cs then
          return
        end
        last_cs = cs
        vim.notify(
          ("Omarchy theme%s → %s"):format(tag or "", cs),
          vim.log.levels.INFO,
          { title = "Omarchy · Theme" }
        )
        ensure_and_apply(cs)
      end

      -- Wait for Lazy to finish booting before first apply
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          if vim.fn.filereadable(theme_lua) == 1 then
            on_theme_change(" (startup)")
          end
        end,
      })

      -- Directory watcher (debounced)
      local debounce_ms = 250
      local timer = uv.new_timer()
      local function schedule_rescan()
        timer:stop()
        timer:start(debounce_ms, 0, function()
          vim.schedule(function()
            on_theme_change("")
          end)
        end)
      end

      local handle = uv.new_fs_event()
      if not handle then
        vim.notify("Unable to create fs_event handle", vim.log.levels.ERROR, { title = "Omarchy" })
        return
      end

      local function on_change(err, filename, status)
        if err then
          vim.schedule(function()
            vim.notify("Watcher error: " .. err, vim.log.levels.ERROR, { title = "Omarchy" })
          end)
          return
        end
        schedule_rescan()
        if filename == "background" then
          vim.schedule(function()
            local bg = read_background()
            if bg then
              vim.o.background = bg
            end
            vim.notify("Omarchy background changed", vim.log.levels.DEBUG, { title = "Omarchy · Background" })
          end)
        end
      end

      local ok, err = handle:start(om_dir, {}, on_change)
      if not ok then
        vim.notify("Failed to start watcher: " .. tostring(err), vim.log.levels.ERROR, { title = "Omarchy" })
        return
      end

      vim.api.nvim_create_autocmd("VimLeavePre", {
        group = vim.api.nvim_create_augroup("OmarchyWatcher", { clear = true }),
        callback = function()
          pcall(function()
            handle:stop()
          end)
          pcall(function()
            handle:close()
          end)
          pcall(function()
            timer:stop()
            timer:close()
          end)
        end,
      })
    end,
  },
}
