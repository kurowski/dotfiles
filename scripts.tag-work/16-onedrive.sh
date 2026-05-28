#!/usr/bin/env bash
# Enable the OneDrive user sync service. First-time auth is a browser
# flow run manually (`onedrive`); the script idles until that's done.
set -euo pipefail

command -v onedrive >/dev/null 2>&1 || exit 0

if [[ ! -f "$HOME/.config/onedrive/refresh_token" ]]; then
  echo "onedrive: not authenticated yet. Run 'onedrive' once to complete" >&2
  echo "          the browser auth flow, then re-apply." >&2
  exit 0
fi

if ! systemctl --user is-enabled onedrive.service >/dev/null 2>&1; then
  systemctl --user enable --now onedrive.service
fi
