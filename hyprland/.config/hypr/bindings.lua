-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- Note: the pre-quattro ~/.config/hypr/bindings.conf had ~20 app-launch binds
-- (browser, webapps, Signal, Obsidian, etc.) but those were just an old
-- capture of Omarchy's own default bindings, not real customizations —
-- Omarchy's current default bindings/applications.lua already covers all of
-- them, so they were intentionally left out here. Only the binds below were
-- genuinely yours.

local home = os.getenv("HOME")

-- Cycle through the configured keyboard layouts (us,tr,il — see input.lua).
o.bind("SUPER + BACKSLASH", "Cycle keyboard layout", home .. "/.local/bin/hypr-cycle-layouts")
o.bind("SUPER + SHIFT + BACKSLASH", "Cycle keyboard layout (prev)", home .. "/.local/bin/hypr-cycle-layouts --prev")

-- Extra shortcuts alongside (not replacing) Omarchy's defaults
-- (SUPER+W already closes, SUPER+CTRL+T already opens Activity/btop).
o.bind("SUPER + SHIFT + Q", "Close window", hl.dsp.window.close())
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
