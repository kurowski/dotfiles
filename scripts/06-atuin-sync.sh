#!/usr/bin/env bash
# Log atuin in to its sync server using credentials stored in 1Password.
# Requires the desktop app's CLI integration to be enabled so `op read`
# can unlock without an interactive sign-in.
set -euo pipefail

[[ "${ATUIN_SYNC:-}" == "true" ]] || exit 0
command -v atuin >/dev/null 2>&1 || exit 0

# `atuin status` exits non-zero with "not logged in to a sync server"
# when no account is configured. Clean exit = already logged in.
if atuin status >/dev/null 2>&1; then
  exit 0
fi

if ! command -v op >/dev/null 2>&1 || ! op vault list --account "$OP_ACCOUNT" >/dev/null 2>&1; then
  echo "atuin sync requested but op CLI is not signed in to $OP_ACCOUNT; skipping" >&2
  exit 0
fi

atuin login \
  -u "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin/username")" \
  -p "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin/password")" \
  -k "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin-key/password")"
