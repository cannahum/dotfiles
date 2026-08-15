# omarchy-shell

Stow package for `~/.config/omarchy/`. Deliberately narrow — it only tracks
the two things actually customized:

```
.config/omarchy/shell.json                            # bar layout, idle timers
.config/omarchy/plugins/cannahum.workspaces/           # cloned bar widget
```

It does **not** track the rest of `~/.config/omarchy/` (`branding/`,
`defaults/`, `extensions/`, `hooks/`, other plugins) — that stays
Omarchy-owned/local, untouched by stow. See `bin/bootstrap-omarchy-shell` for
how this gets adopted safely on top of whatever Omarchy already laid down.

## Why `cannahum.workspaces` is a full clone, not a small patch

Omarchy's bar widgets live read-only under `/usr/share/omarchy/shell/`, and
get overwritten on every Omarchy update. Its documented customization path
(see the `omarchy` skill's `plugins.md`) is: never edit the packaged file,
clone the whole thing into user config instead (`omarchy plugin clone
omarchy.workspaces`). There's no hook to override a single function inside a
shipped widget — the unit of customization is the whole QML file.

We used this to fix a real annoyance: the stock `omarchy.workspaces` widget
hardcodes `var ids = [1, 2, 3, 4, 5]` and renders that same row of buttons on
*every* monitor's bar, regardless of which monitor a workspace actually lives
on — so a two-monitor setup shows "1 2 3 4 5" twice, looking like duplicated
workspaces. Our clone filters the button list to only the workspaces whose
`.monitor.name` matches the bar instance's own screen.

The actual change is small — about 14 lines out of the file's 72:

- add `import Quickshell` (for the `QsWindow` attached property)
- add a `screenName()` helper that reads this bar instance's own output name
- rewrite `workspaceIds()` to filter by `ws.monitor.name === screenName()`
  instead of defaulting to a hardcoded `[1,2,3,4,5]`

Everything else in `Workspaces.qml` — layout, styling, button behavior — is
an unmodified copy of the stock widget.

### The tradeoff

This is now a fork, not an override. If a future Omarchy/quattro update
improves the stock `Workspaces.qml` (new features, style tweaks, bug fixes),
this copy won't pick any of it up automatically — someone has to notice,
diff, and manually re-apply our two changes on top of the new stock file.

A leaner alternative — subclassing the stock QML type and overriding just
`workspaceIds()`/`screenName()` while inheriting everything else live from
the vendor file — was considered and rejected: it would require importing
across an absolute path into Omarchy's internal plugin directory, which
isn't a documented/stable interface. That trades "stale fork" risk for
"silently breaks on the next Omarchy internal reshuffle" risk, which is
worse.

**To check for drift later:**

```bash
diff /usr/share/omarchy/shell/plugins/bar/widgets/Workspaces.qml \
     ~/dotfiles/omarchy-shell/.config/omarchy/plugins/cannahum.workspaces/Workspaces.qml
```

Anything beyond the three changes listed above is either a stock-widget
update we haven't merged in, or drift worth re-reviewing.
