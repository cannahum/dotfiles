-- Extra autostart processes.

-- Ported from pre-quattro ~/.config/hypr/autostart.conf. Your
-- ~/.config/hypr/hyprsunset.conf profiles (day 6500K / night 4000K) are
-- still intact and untouched by the migration — hyprsunset just was never
-- being launched to use them. This is Omarchy's own documented way to wire
-- it up (see the comment in ~/.config/hypr/hyprsunset.conf).
o.launch_on_start("hyprsunset")
