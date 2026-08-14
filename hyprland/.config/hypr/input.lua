-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Ported from pre-quattro ~/.config/hypr/input.conf, dropped by the same
-- conf->lua migration that reset looknfeel.
hl.config({
  input = {
    -- Three keyboard layouts, switched with the cycle bind in bindings.lua.
    kb_layout = "us,tr,il",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 600,

    -- Start with numlock on by default.
    numlock_by_default = true,

    touchpad = {
      natural_scroll = true,

      -- Control the speed of your scrolling.
      scroll_factor = 0.4,
    },
  },
})
