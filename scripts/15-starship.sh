#!/usr/bin/env bash
# starship — not in Fedora's default repos. Install via the upstream
# shell installer into ~/.local/bin (on PATH per .zshrc).
set -euo pipefail

command -v starship >/dev/null 2>&1 && exit 0

mkdir -p "$HOME/.local/bin"
curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" --yes
