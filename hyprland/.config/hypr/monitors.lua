-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 1
local omarchy_monitor_scale = 1

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- "auto" positioning placed monitors in connection order, which put the
-- laptop panel on the left — backwards from the physical desk layout (Dell
-- U2421E on the left, laptop on the right). Pin explicit positions instead:
-- DP-1 anchors the layout at 0x0, and eDP-1 sits to its right, starting
-- where DP-1's logical width (1920px at scale 1) ends.
hl.monitor({ output = "DP-1", mode = "1920x1200@59.95", position = "0x0", scale = 1 })

-- Pre-quattro ~/.config/hypr/monitors.conf pinned the laptop panel to a 1.2
-- fractional scale. This explicit eDP-1 rule (rather than editing
-- omarchy_monitor_scale above) is deliberate: quattro's own
-- omarchy-hyprland-monitor-clamshell / -scaling scripts look for an
-- hl.monitor rule keyed on the laptop's output name and keep it in sync
-- (e.g. Super+scroll scaling adjustments get written back here), while the
-- generic catch-all above stays free to apply to any external monitor.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "1920x0", scale = 1.2 })

-- XWayland apps may render blurry at a fractional scale like 1.2. The old
-- config paired this with xwayland.force_zero_scaling = false — left out for
-- now; add it back if XWayland apps actually look off:
-- hl.config({ xwayland = { force_zero_scaling = false } })
