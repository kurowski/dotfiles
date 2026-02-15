#!/usr/bin/env bash
# Lightweight dotfiles installer for devcontainers.
# No Ansible required — just symlinks shell/editor config.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$1" dest="$2"
  if [ -e "$dest" ] || [ -L "$dest" ]; then
    rm -f "$dest"
  fi
  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
}

# Shell config — will be populated in future plans
# link "$DOTFILES_DIR/files/zshrc" "$HOME/.zshrc"
# link "$DOTFILES_DIR/files/starship.toml" "$HOME/.config/starship.toml"

echo "Dotfiles installed."
