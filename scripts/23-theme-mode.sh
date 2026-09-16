#!/usr/bin/env bash
# theme-mode — resolve light/dark once per apply, and on desktop hosts keep
# following the desktop afterwards via a systemd user service.
#
# The reload runs everywhere, not just where the watcher does: the state file it
# writes is what .zshrc and nvim read, so a headless host needs it too. It's
# just that there the answer never changes.
set -euo pipefail

# By path, not by name: scripts run under bash, which never sources .zshrc and
# so doesn't have ~/.local/bin on PATH.
theme_mode="$HOME/.local/bin/theme-mode"
[[ -x "$theme_mode" ]] || exit 0

"$theme_mode" reload

# Everything below is the watcher, which only makes sense with a desktop session
# to follow. Every desktop host gets one, not just the ones whose desktop
# switches on a schedule: a manual toggle is the same signal, and tmux and nvim
# need the nudge either way.
#
# macOS gets there by a different route. There's no appearance signal on a bus,
# but the setting does land in a file, so launchd's WatchPaths is the watcher
# and there's no long-running process to supervise — hence a one-shot `reload`
# job rather than `theme-mode watch`. See the plist for the measurements.
case ",$HOMIE_TAGS," in
  *,macos,*)
    plist="$HOME/Library/LaunchAgents/net.kurowski.theme-mode.plist"
    [[ -e "$plist" ]] || { echo "theme-mode.plist not applied yet; skipping" >&2; exit 0; }

    # bootout-then-bootstrap for the same reason the Linux path does
    # daemon-reload-then-restart: launchd caches the job it loaded, so an edited
    # plist doesn't take until the old one is gone. Tolerate the bootout
    # failing — on a first apply there's nothing loaded to remove.
    launchctl bootout "gui/$(id -u)/net.kurowski.theme-mode" 2>/dev/null || true
    launchctl bootstrap "gui/$(id -u)" "$plist"
    exit 0
    ;;
  *,container,*) exit 0 ;;
  *,desktop,*) ;;
  *) exit 0 ;;  # servers: nothing to follow
esac
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
