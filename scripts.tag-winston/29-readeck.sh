#!/usr/bin/env bash
# Readeck (read-it-later, replaced Readwise Reader 2026-10-31) on winston.
#
# The compose file lives in system.tag-winston/opt/readeck/ and is copied —
# not symlinked — into /opt/readeck, so compose's project directory, and with
# it the relative ./data volume, stays /opt/readeck. ./data itself is never
# touched here; a fresh host starts empty and is restored by hand with
# `readeck import` from the weekly export (see 30-backups.sh).
#
# Tailnet-only: the container binds 127.0.0.1:8000 and `tailscale serve`
# publishes it as https://winston.tail5aa588.ts.net:8443. 443 stays free for
# Seafile.
set -euo pipefail

src="$(dirname "${BASH_SOURCE[0]}")/../system.tag-winston/opt/readeck/docker-compose.yml"
dir=/opt/readeck

command -v docker >/dev/null 2>&1 || { echo "readeck: docker not found, skipping" >&2; exit 0; }

# /opt is root-owned; the directory itself is ours so later edits and
# `docker compose` need no sudo.
if [[ ! -d "$dir" ]]; then
  sudo install -d -o "$(id -un)" -g "$(id -gn)" "$dir"
fi

# Only (re)start the stack when the compose file actually changed, so a
# routine apply never bounces the container.
if ! cmp -s "$src" "$dir/docker-compose.yml"; then
  install -m 0644 "$src" "$dir/docker-compose.yml"
  docker compose --project-directory "$dir" -f "$dir/docker-compose.yml" up -d
fi

# tailscale serve config persists in tailscaled's state; set it only when the
# 8443 handler is missing. 08-tailscale.sh makes us the operator, so no sudo.
if command -v tailscale >/dev/null 2>&1; then
  if ! tailscale serve status --json 2>/dev/null | grep -q '"Proxy": *"http://127.0.0.1:8000"'; then
    tailscale serve --bg --https=8443 http://127.0.0.1:8000 \
      || echo "readeck: could not configure tailscale serve (is tailscale up?)" >&2
  fi
fi
