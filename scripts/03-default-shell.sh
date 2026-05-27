#!/usr/bin/env bash
# Switch the user's login shell to zsh.
set -euo pipefail

target=/usr/bin/zsh
[[ -x "$target" ]] || exit 0
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$target" ]] && exit 0

sudo chsh -s "$target" "$USER"
