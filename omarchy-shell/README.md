# omarchy-shell

Stow package for `~/.config/omarchy/`. Deliberately narrow — it only tracks
the one thing actually customized:

```
.config/omarchy/shell.json    # bar layout, idle timers
```

It does **not** track the rest of `~/.config/omarchy/` (`branding/`,
`defaults/`, `extensions/`, `hooks/`, plugins) — that stays Omarchy-owned/local,
untouched by stow. See `bin/bootstrap-omarchy-shell` for how this gets adopted
safely on top of whatever Omarchy already laid down.

## History: the `cannahum.workspaces` fork is gone

This package used to carry `cannahum.workspaces`, a clone of the stock
`omarchy.workspaces` bar widget. The stock widget hardcoded workspaces 1-5 and
showed the same row on every monitor, so the clone filtered buttons to the
workspaces living on each bar's own monitor.

Omarchy later made workspaces per-monitor (`default/hypr/monitor-workspaces.lua`):
each monitor owns a block of ten Hyprland IDs (laptop 1-10, next monitor 11-20,
...), and the stock widget now shows each monitor's own block numbered 1-10.
The fork's `id <= 10` filter then hid every workspace on the external monitor,
so its bar showed no indexes. The fork is deleted and `shell.json` uses
`omarchy.workspaces` again.

Lesson: prefer stock widgets; a cloned widget silently goes stale when upstream
changes the model underneath it.
