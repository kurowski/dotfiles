#!/usr/bin/env bash
# Enable tailscaled on personal hosts. `tailscale up` is interactive
# and needs a browser auth — left to the user the first time.
set -euo pipefail

case ",$HM_TAGS," in *,personal,*) ;; *) exit 0 ;; esac
command -v tailscale >/dev/null 2>&1 || exit 0

if ! systemctl is-enabled tailscaled >/dev/null 2>&1; then
  sudo systemctl enable --now tailscaled
fi
