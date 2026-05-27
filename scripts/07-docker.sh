#!/usr/bin/env bash
# Enable the docker daemon, add the current user to the docker group,
# then log Docker into GHCR using gh's existing auth token (needed for
# private org images like ghcr.io/uceap/*).
set -euo pipefail

command -v docker >/dev/null 2>&1 || exit 0

if ! systemctl is-enabled docker >/dev/null 2>&1; then
  sudo systemctl enable --now docker
fi

if ! id -nG "$USER" | grep -qw docker; then
  sudo usermod -aG docker "$USER"
  echo "added $USER to docker group (takes effect on next login)"
fi

if command -v gh >/dev/null 2>&1 \
  && docker system info >/dev/null 2>&1 \
  && gh auth status >/dev/null 2>&1; then
  gh auth token | docker login ghcr.io \
    -u "$(gh api user --jq .login 2>/dev/null || echo oauth2)" \
    --password-stdin
fi
