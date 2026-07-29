#!/usr/bin/env bash
# Wire the Hyprland session's daemons into systemd.
#
# Why any of this is needed: /usr/bin/start-hyprland has no systemd integration
# at all, so a bare Hyprland session never reaches graphical-session.target and
# never exports WAYLAND_DISPLAY into the systemd activation environment. Every
# daemon this session wants — hyprpaper, hypridle, swaync, hyprpolkitagent,
# waybar — ships a unit that is WantedBy=graphical-session.target with
# ConditionEnvironment=WAYLAND_DISPLAY, and so does theme-mode.service, which is
# what makes THEME = "auto" follow the desktop. All of them would sit dead.
#
# uwsm fixes that by running the compositor as a systemd unit. Hyprland ships
# hyprland-uwsm.desktop for it; sddm lists it as "Hyprland (uwsm-managed)".
#
# The units are bound to uwsm's per-compositor target rather than enabled
# globally. cece also boots Plasma, and a globally-enabled swaync would claim
# org.freedesktop.Notifications there, hypridle would fight powerdevil, and
# waybar would draw a second bar over Plasma's panel.
set -euo pipefail

command -v systemctl >/dev/null 2>&1 || exit 0
command -v uwsm      >/dev/null 2>&1 || { echo "uwsm not installed; skipping" >&2; exit 0; }

# The instance name uwsm derives from the session's Exec line,
# `uwsm start -e -D Hyprland hyprland.desktop` — which is the *full desktop
# entry ID*, dot-suffix included. So the target is
# wayland-session@hyprland.desktop.target, not wayland-session@hyprland.target.
#
# This bit me: an earlier version bound to the short name. Checking that the
# `wayland-session@.target` template existed passed happily, because templates
# instantiate for any name — a target instance nothing ever activates is a
# perfectly valid unit. The session came up with no bar, no wallpaper and no
# idle handling, and no error anywhere to say why.
#
# So the assertion below is against the *instance*, not the template, and it
# prefers what's actually running over what's predicted. In a live Hyprland
# session that's authoritative; during a first provision there's no session yet,
# and the literal is the right answer.
target=$(systemctl --user list-units --state=active --no-legend --no-pager \
           'wayland-session@*.target' 2>/dev/null | awk '{print $1; exit}')
target="${target:-wayland-session@hyprland.desktop.target}"

if ! systemctl --user cat "$target" >/dev/null 2>&1; then
  echo "uwsm target $target not found; skipping unit wiring" >&2
  echo "  (check 'systemctl --user list-units wayland-session@*.target --all')" >&2
  exit 0
fi

# Clear out wants under any *other* wayland-session instance. Without this an
# instance-name change leaves the old directory behind, and `is-enabled` keeps
# reporting these units as enabled against a target that never activates.
for stale in "$HOME/.config/systemd/user/"wayland-session@*.target.wants; do
  [[ -d "$stale" ]] || continue
  [[ "$stale" == *"/$target.wants" ]] && continue
  echo "  removing stale wants: ${stale##*/}" >&2
  rm -rf "$stale"
done

# Re-read unit files first. homie re-symlinks the drop-ins under
# ~/.config/systemd/user on every apply, and add-wants against a stale view is
# how you get a Wants pointing at a unit systemd doesn't think exists yet.
systemctl --user daemon-reload

# Order is not significant — the units carry their own After= — but the list is
# the full set of things that should exist in a Hyprland session and nowhere
# else.
units=(
  hyprpaper.service        # wallpaper
  hypridle.service         # idle/lock/suspend, replacing powerdevil
  hyprpolkitagent.service  # authentication dialogs
  swaync.service           # notifications
  waybar.service           # the bar
)

for unit in "${units[@]}"; do
  # Skip anything not installed rather than failing the whole apply — the AUR
  # half of this tag can legitimately be mid-rebuild.
  systemctl --user cat "$unit" >/dev/null 2>&1 || {
    echo "  $unit not installed, skipping" >&2
    continue
  }
  systemctl --user add-wants "$target" "$unit" >/dev/null
done

# And once more, so the Wants just written are visible to a session started
# immediately after this.
systemctl --user daemon-reload

# Deliberately not enabled and not started here. Starting them needs a running
# Wayland session, which `hm apply` isn't; they come up with the target on the
# next login. Nor is the sddm session preselected — cece keeps both Plasma and
# Hyprland, and which one it lands in is the user's call at the greeter.
echo "hyprland session units bound to $target"
