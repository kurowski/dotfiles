#!/usr/bin/env bash
# zsh-patina — fast Rust syntax highlighter (shared background daemon,
# sub-millisecond highlighting). Built via cargo; rustup is provisioned by
# 01-rust-toolchain.sh. Activated at the very end of .zshrc. Its default
# theme uses the 8 ANSI colors, so it inherits the terminal's catppuccin
# palette automatically — no per-host theming needed.
set -euo pipefail
command -v zsh-patina >/dev/null 2>&1 && exit 0

# cargo may not be on PATH in a non-login script environment.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
command -v cargo >/dev/null 2>&1 || { echo "zsh-patina: cargo not found, skipping" >&2; exit 0; }

cargo install --locked zsh-patina
