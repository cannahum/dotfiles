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

      -- -------------------------
      -- Logging -- example use: OMARCHY_THEME_LOG=debug nvim
      -- -------------------------
      local LOG_PATH = vim.fn.stdpath("state") .. "/omarchy-theme.log"

      local LEVELS = { error = 1, warn = 2, info = 3, debug = 4, trace = 5 }
      local LOG_LEVEL = (vim.g.omarchy_theme_log or vim.env.OMARCHY_THEME_LOG or "warn"):lower()
      if not LEVELS[LOG_LEVEL] then
        LOG_LEVEL = "warn"
      end

      local function log(level_or_fmt, maybe_fmt, ...)
        local level, fmt, args = "debug", level_or_fmt, { ... }

        if LEVELS[level_or_fmt] then
          level, fmt, args = level_or_fmt, maybe_fmt, { ... }
        end
        if not fmt or LEVELS[level] > LEVELS[LOG_LEVEL] then
          return
        end

        local msg = os.date("%H:%M:%S ") .. string.format(fmt, unpack(args))

        local notify_level = vim.log.levels.DEBUG
        if level == "info" then
          notify_level = vim.log.levels.INFO
        end
        if level == "warn" then
          notify_level = vim.log.levels.WARN
        end
        if level == "error" then
          notify_level = vim.log.levels.ERROR
        end

        if LEVELS[level] <= LEVELS["warn"] then
          pcall(vim.notify, msg, notify_level, { title = "Omarchy · Theme" })
        end

        local fd = uv.fs_open(LOG_PATH, "a", 438) -- 0666
        if fd then
          uv.fs_write(fd, msg .. "\n", -1)
          uv.fs_close(fd)
        end
      end

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
          log("trace", "read_colorscheme: no file")
          return nil
        end
        local m = data:match('colorscheme%s*=%s*"([^"]+)"')
          or data:match("colorscheme%s*=%s*'([^']+)'")
          or data:match('vim%.cmd%.colorscheme%(%s*"([^"]+)"%s*%)')
          or data:match("vim%.cmd%.colorscheme%(%s*'([^']+)'%s*%)")
          or data:match('vim%.cmd%(%s*"colorscheme%s+([^"]+)"%s*%)')
          or data:match("vim%.cmd%(%s*'colorscheme%s+([^']+)'%s*%)")
        log("trace", "read_colorscheme -> %s", tostring(m))
        return m
      end

      local function read_background()
        local b = slurp(bg_file)
        if not b then
          log("trace", "read_background: no file")
          return nil
        end
        b = b:gsub("%s+", "")
        if b == "light" or b == "dark" then
          log("trace", "read_background -> %s", b)
          return b
        end
        log("trace", "read_background: invalid '%s'", b)
        return nil
      end

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

      local function refresh_statuslines()
        local ok, lualine = pcall(require, "lualine")
        if ok then
          lualine.setup({ options = { theme = "auto" } })
          lualine.refresh()
        end
      end

      local function ensure_and_apply(cs)
        local ok_lazy, Lazy = pcall(require, "lazy")
        if not ok_lazy then
          return
        end

        local bg = read_background()
        if bg then
          if vim.o.background ~= bg then
            log("info", "ensure_and_apply: set background -> %s", bg)
          end
          vim.o.background = bg
        end
        vim.o.termguicolors = true

        local plugin_name = known[cs]
        if plugin_name then
          pcall(Lazy.load, { plugins = { plugin_name }, wait = true })
        end

        local function apply()
          log("info", "apply: colorscheme %s (bg=%s)", cs, vim.o.background)
          local ok, err = pcall(vim.cmd.colorscheme, cs)
          if not ok then
            log("warn", "apply: first attempt failed: %s", tostring(err))
            vim.defer_fn(function()
              local ok2, err2 = pcall(vim.cmd.colorscheme, cs)
              if not ok2 then
                log("error", "apply: second attempt failed: %s", tostring(err2))
                vim.notify(
                  ("Failed to set colorscheme '%s': %s"):format(cs, tostring(err2)),
                  vim.log.levels.WARN,
                  { title = "Omarchy · Theme" }
                )
              else
                log("info", "apply: second attempt succeeded")
                refresh_statuslines()
              end
            end, 500)
          else
            log("info", "apply: success")
            refresh_statuslines()
          end
        end

        apply()
      end

      local last_key = nil
      local function current_key()
        local cs = read_colorscheme() or (vim.g.colors_name or "unknown")
        local bg = (vim.o.background == "light" or vim.o.background == "dark") and vim.o.background or ""
        return ("%s|%s"):format(cs, bg), cs, bg
      end

      local function on_theme_change(tag, force)
        local key, cs, bg = current_key()
        log(
          "debug",
          "on_theme_change%s: key=%s (last=%s) force=%s",
          tag or "",
          key,
          tostring(last_key),
          tostring(force)
        )
        if not force and key == last_key then
          log("trace", "on_theme_change: no-op (unchanged)")
          return
        end
        last_key = key
        ensure_and_apply(cs)
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
          if vim.fn.filereadable(theme_lua) == 1 then
            on_theme_change(" (startup)")
          end
        end,
      })

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
            log("error", "fs_event error: %s", err)
            vim.notify("Watcher error: " .. err, vim.log.levels.ERROR, { title = "Omarchy" })
          end)
          return
        end

        log("trace", "fs_event: filename=%s status=%s", tostring(filename), tostring(status))

        if filename == "background" then
          vim.schedule(function()
            local bg = read_background()
            if bg and vim.o.background ~= bg then
              log("info", "fs_event: applying background -> %s", bg)
              vim.o.background = bg
            else
              log("trace", "fs_event: background unchanged (vim=%s, file=%s)", tostring(vim.o.background), tostring(bg))
            end
            schedule_rescan()
            on_theme_change(" (bg file)", true)
          end)
          return
        end

        schedule_rescan()
      end
      local ok, err = handle:start(om_dir, {}, on_change)
      if not ok then
        vim.notify("Failed to start watcher: " .. tostring(err), vim.log.levels.ERROR, { title = "Omarchy" })
        return
      end

      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        callback = function()
          log("debug", "OptionSet(background): vim.o.background=%s", tostring(vim.o.background))
          on_theme_change(" (OptionSet)", true)
        end,
      })

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
