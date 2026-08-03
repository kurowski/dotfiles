#!/usr/bin/env bash
# Enable sddm. The Fedora and Ubuntu KDE hosts got a display manager enabled
# by their installer; on Arch the DE comes from [packages."tag:kde"] and the
# unit ships disabled, so without this an Arch KDE host boots to a TTY.
set -euo pipefail

[[ -f /usr/lib/systemd/system/sddm.service ]] || exit 0

# display-manager.service is the alias systemd actually boots, so asking about
# it covers both halves of the job in one check: it's already sddm (nothing to
# do on a re-apply), or it's some other display manager somebody chose
# deliberately, which this has no business overwriting.
if systemctl is-enabled display-manager.service >/dev/null 2>&1; then
  exit 0
fi

# No --now. Starting a display manager takes over the console, which mid-apply
# means yanking the session running `hm apply`. Enabling it is enough — it
# comes up on the next boot, and provisioning a fresh install ends in one
# anyway.
sudo systemctl enable sddm
