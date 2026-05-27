#!/usr/bin/env bash
# Fedora ships `rustup` as just the bootstrapper; the real toolchain
# lands in ~/.cargo/bin after rustup-init. --no-modify-path because
# .zshrc already adds ~/.cargo/bin.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac
[[ -x "$HOME/.cargo/bin/rustup" ]] && exit 0
command -v rustup-init >/dev/null 2>&1 || exit 0

rustup-init -y --default-toolchain stable --no-modify-path
