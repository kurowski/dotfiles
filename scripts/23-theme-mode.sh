#!/usr/bin/env bash
# theme-mode — resolve light/dark once per apply, and on THEME = "auto" hosts
# keep following the desktop afterwards via a systemd user service.
#
# The reload runs everywhere, not just on auto hosts: the state file it writes
# is what .zshrc and nvim read, so a pinned light/dark host needs it too. It's
# just that on those hosts the answer never changes.
set -euo pipefail

# By path, not by name: scripts run under bash, which never sources .zshrc and
# so doesn't have ~/.local/bin on PATH.
theme_mode="$HOME/.local/bin/theme-mode"
[[ -x "$theme_mode" ]] || exit 0

"$theme_mode" reload

# Everything below is the watcher, which only makes sense with a desktop
# session and a portal to ask.
[[ "${THEME:-}" == "auto" ]] || exit 0
case ",$HM_TAGS," in *,macos,*|*,container,*) exit 0 ;; esac
command -v systemctl >/dev/null 2>&1 || exit 0

unit="$HOME/.config/systemd/user/theme-mode.service"
[[ -e "$unit" ]] || { echo "theme-mode.service not applied yet; skipping" >&2; exit 0; }

# homie re-symlinks unit files on every apply, so re-read them before deciding
# anything. Cheap, and skipping it is how you get a stale unit running.
systemctl --user daemon-reload

systemctl --user enable theme-mode.service >/dev/null

# `enable` alone won't start it mid-session, and `restart` (rather than start)
# picks up edits to the unit or the script on a re-apply.
if systemctl --user is-active --quiet graphical-session.target; then
  systemctl --user restart theme-mode.service
fi
