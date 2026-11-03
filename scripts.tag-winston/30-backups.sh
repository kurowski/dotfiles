#!/usr/bin/env bash
# winston's nightly backups (Ente export, Readeck export, rclone -> B2), as
# plain systemd units in system.tag-winston/etc/systemd/system/, ported from
# the old Ansible rclone_backups role. The README's "winston: services and
# backups" section has the schedule and what's set up by hand (rclone.conf,
# the ente CLI, the B2 lifecycle rule).
set -euo pipefail

units="$(dirname "${BASH_SOURCE[0]}")/../system.tag-winston/etc/systemd/system"
dest=/etc/systemd/system

mkdir -p "$HOME/Drive/Archive/readeck"

# Compare before writing so a re-apply on a host that's already correct
# doesn't prompt for sudo.
changed=()
for f in "$units"/*.service "$units"/*.timer; do
  name=$(basename "$f")
  if ! cmp -s "$f" "$dest/$name"; then
    sudo install -m 0644 "$f" "$dest/$name"
    changed+=("$name")
  fi
done

if (( ${#changed[@]} )); then
  sudo systemctl daemon-reload
fi

for f in "$units"/*.timer; do
  timer=$(basename "$f")
  if ! systemctl is-enabled "$timer" >/dev/null 2>&1; then
    sudo systemctl enable --now "$timer"
  elif [[ " ${changed[*]} " == *" $timer "* ]]; then
    # Pick up a changed OnCalendar now rather than after the next fire.
    sudo systemctl restart "$timer"
  fi
done
