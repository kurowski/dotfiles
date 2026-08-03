#!/usr/bin/env bash
# Enable tailscaled on personal hosts. `tailscale up` is interactive
# and needs a browser auth — left to the user the first time.
set -euo pipefail

command -v tailscale >/dev/null 2>&1 || exit 0

if ! systemctl is-enabled tailscaled >/dev/null 2>&1; then
  sudo systemctl enable --now tailscaled
fi

# Without an operator, every `tailscale up/down/set` needs sudo. Claim
# it for the invoking user — `id -un` rather than $USER, which homie's
# clean script env doesn't set.
#
# Short-circuits when it's already ours so re-applies don't prompt for
# sudo. If the read fails (daemon not up yet, or `debug prefs` changes
# shape) we fall through and set it again: harmless and idempotent, and
# a recurring sudo prompt is a louder failure than silently skipping.
user=$(id -un)
operator=$(tailscale debug prefs 2>/dev/null \
  | sed -n 's/.*"OperatorUser": *"\([^"]*\)".*/\1/p')

if [[ "$operator" != "$user" ]]; then
  sudo tailscale set --operator="$user" \
    || echo "could not set tailscale operator; run it manually" >&2
fi
