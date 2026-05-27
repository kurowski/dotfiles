#!/usr/bin/env bash
# Debian trixie ships neovim 0.10, but AstroNvim needs >= 0.11. Pull
# the upstream prebuilt under ~/.local/nvim and symlink into
# ~/.local/bin (ahead of /usr/bin on PATH per .zshrc).
set -euo pipefail

case ",$HM_TAGS," in *,debian,*|*,ubuntu,*) ;; *) exit 0 ;; esac
prefix="$HOME/.local/nvim"
[[ -x "$prefix/bin/nvim" ]] && exit 0

case "$(uname -m)" in
  x86_64)  arch="linux-x86_64" ;;
  aarch64) arch="linux-arm64" ;;
  *) echo "unsupported arch for neovim: $(uname -m); skipping" >&2; exit 0 ;;
esac

mkdir -p "$HOME/.local/bin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "https://github.com/neovim/neovim/releases/latest/download/nvim-${arch}.tar.gz" \
  | tar xz -C "$tmp"
rm -rf "$prefix"
mv "$tmp/nvim-${arch}" "$prefix"
ln -snf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
