#!/usr/bin/env bash
# Log atuin in to its sync server. Two credential sources:
#
# - ATUIN_KEY / ATUIN_PASSWORD in the environment. This is the devcontainer
#   path: the host's op-env-session exports them from 1Password, and the
#   project devcontainer.json forwards them via ${localEnv:...}. Containers
#   have no host file (so no ATUIN_SYNC) and no `op`, which is why this has
#   to come first.
# - 1Password directly, on hosts with ATUIN_SYNC=true. Requires the desktop
#   app's CLI integration to be enabled so `op read` can unlock without an
#   interactive sign-in.
set -euo pipefail

command -v atuin >/dev/null 2>&1 || exit 0

# `atuin status` exits non-zero with "not logged in to a sync server"
# when no account is configured. Clean exit = already logged in.
if atuin status >/dev/null 2>&1; then
  exit 0
fi

if [[ -n "${ATUIN_KEY:-}" && -n "${ATUIN_PASSWORD:-}" ]]; then
  atuin login -u "${ATUIN_USERNAME:-bkurowski}" -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY"
  exit 0
fi

[[ "${ATUIN_SYNC:-}" == "true" ]] || exit 0

if ! command -v op >/dev/null 2>&1 || ! op vault list --account "$OP_ACCOUNT" >/dev/null 2>&1; then
  echo "atuin sync requested but op CLI is not signed in to $OP_ACCOUNT; skipping" >&2
  exit 0
fi

atuin login \
  -u "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/oxw3y4cgyarlmbkcuuxrt32ory/username")" \
  -p "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/oxw3y4cgyarlmbkcuuxrt32ory/password")" \
  -k "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin-key/password")"
