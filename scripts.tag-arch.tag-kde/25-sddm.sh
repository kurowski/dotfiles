#!/usr/bin/env bash
# Enable and theme sddm. The Fedora and Ubuntu KDE hosts got a display manager
# enabled by their installer; on Arch the DE comes from [packages."tag:kde"] and
# the unit ships disabled, so without this cece boots to a TTY.
set -euo pipefail

[[ -f /usr/lib/systemd/system/sddm.service ]] || exit 0

# display-manager.service is the alias systemd actually boots. Three cases:
#
#   nothing enabled          → enable sddm
#   enabled, and it's sddm   → nothing to enable, but still ours to theme
#   enabled, something else  → somebody chose that deliberately; leave entirely
#
# The middle case is the common one on a re-apply, and it is why this is a
# three-way check rather than "is anything enabled, if so stop". Bailing there
# would skip the theming below on every host that's already provisioned — which
# is every host, after the first run.
dm=$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null || true)

if [[ -z "$dm" ]]; then
  # No --now. Starting a display manager takes over the console, which mid-apply
  # means yanking the session running `hm apply`. Enabling it is enough — it
  # comes up on the next boot, and provisioning a fresh install ends in one
  # anyway.
  sudo systemctl enable sddm
elif [[ "$dm" != */sddm.service ]]; then
  echo "display-manager is ${dm##*/}, not sddm; leaving it alone" >&2
  exit 0
fi

# Theme the greeter, when the theme is installed — it comes from the hyprland
# tag's AUR list, so a kde-only host reaches here and skips.
#
# Pinned to mocha rather than following THEME. The greeter runs before any
# session exists, so there's no portal to ask and no ~/.local/state to read: it
# has no way to know what the desktop is set to, and cece is "auto". Dark is the
# same fallback theme-mode uses when it can't resolve, and a login screen at
# boot is the one surface where a white flash is actually unpleasant.
theme="catppuccin-mocha-mauve"
[[ -d "/usr/share/sddm/themes/$theme" ]] || exit 0

current=$(awk -F= '/^Current=/ {print $2}' /etc/sddm.conf.d/10-theme.conf 2>/dev/null || true)
if [[ "$current" != "$theme" ]]; then
  sudo install -d /etc/sddm.conf.d
  printf '[Theme]\nCurrent=%s\n' "$theme" | sudo tee /etc/sddm.conf.d/10-theme.conf >/dev/null
  echo "sddm theme set to $theme"
fi
