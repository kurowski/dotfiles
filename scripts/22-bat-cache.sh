#!/usr/bin/env bash
# bat ships no Catppuccin theme; the .tmTheme files are dropped into
# ~/.config/bat/themes/ as dotfiles. bat only sees them after its theme
# cache is (re)built. Idempotent: rebuilding is cheap and safe to repeat.
set -euo pipefail

# Debian/Ubuntu install the binary as `batcat`.
if command -v bat >/dev/null 2>&1; then
  bat_bin=bat
elif command -v batcat >/dev/null 2>&1; then
  bat_bin=batcat
else
  exit 0
fi

"$bat_bin" cache --build
