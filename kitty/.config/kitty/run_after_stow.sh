#!/usr/bin/env bash
set -euo pipefail

KITTY_DIR="$(dirname "$0")"   # directory of this script (~/.config/kitty)
OMARCHY_THEME="$HOME/.config/omarchy/current/theme/kitty.conf"
FALLBACK_THEME="$KITTY_DIR/fallback-theme.conf"
THEME_LINK="$KITTY_DIR/theme.conf"

if [[ -f "$OMARCHY_THEME" ]]; then
  ln -sf "$OMARCHY_THEME" "$THEME_LINK"
  echo "[kitty] theme.conf -> Omarchy theme"
elif [[ -f "$FALLBACK_THEME" ]]; then
  ln -sf "$FALLBACK_THEME" "$THEME_LINK"
  echo "[kitty] theme.conf -> fallback (current-theme.conf)"
else
  echo "[kitty] WARNING: no theme found (neither Omarchy nor fallback)."
fi

