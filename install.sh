#!/usr/bin/env bash
# Lightweight dotfiles installer for devcontainers.
# No Ansible required — just symlinks config and installs CLI tools.
# VS Code clones the dotfiles repo and runs this script automatically.

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Install starship if not present
if ! command -v starship >/dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# Install atuin if not present
if ! command -v atuin >/dev/null 2>&1; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh
fi

# Starship config — render the Jinja2 template with iceberg_light palette
mkdir -p "$HOME/.config"
sed "s/{% if theme == 'dark' %}gruvbox_dark{% else %}iceberg_light{% endif %}/iceberg_light/" \
  "$DOTFILES_DIR/roles/shell/templates/starship.toml.j2" > "$HOME/.config/starship.toml"

# Shell init — append to .zshrc if zsh exists
if [ -f "$HOME/.zshrc" ]; then
  # Only append if we haven't already
  if ! grep -q 'managed by dotfiles install.sh' "$HOME/.zshrc"; then
    cat >> "$HOME/.zshrc" << 'ZSHRC'

# --- managed by dotfiles install.sh ---
export PATH="$HOME/.atuin/bin:$HOME/.local/bin:$PATH"

# Atuin
export ATUIN_INIT_FLAGS="--disable-up-arrow"
if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh ${ATUIN_INIT_FLAGS})"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
ZSHRC
  fi
fi

echo "Dotfiles installed."
