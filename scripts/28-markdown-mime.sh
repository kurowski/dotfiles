#!/usr/bin/env bash
# Point text/markdown at whatever the desktop's default browser is, so
# `open`/`xdg-open` on a .md file renders it instead of dumping it into
# KWrite (or GNOME Text Editor). Re-derived every apply rather than seeded
# once: the goal is to always track the *current* default browser (Firefox
# on personal hosts, Chrome on work), so it stays correct if that ever
# changes, unlike theme-mode's color-scheme seed which must not stomp a
# manual toggle.
set -euo pipefail

# Same shape as 23-theme-mode.sh: meaningful only with a desktop session,
# and macOS has no xdg-mime at all.
case ",$HOMIE_TAGS," in
  *,macos,*|*,container,*) exit 0 ;;
  *,desktop,*) ;;
  *) exit 0 ;;  # servers: no desktop session to ask
esac

command -v xdg-mime >/dev/null 2>&1 && command -v xdg-settings >/dev/null 2>&1 || exit 0

browser="$(xdg-settings get default-web-browser 2>/dev/null)" || exit 0
[[ -n "$browser" ]] || exit 0

xdg-mime default "$browser" text/markdown
