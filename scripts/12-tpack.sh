#!/usr/bin/env bash
# tpack (tmux plugin manager, drop-in tpm replacement) — not in any
# distro repo. Grab the prebuilt linux binary from the upstream
# release and drop it in ~/.local/bin (on PATH via .zshrc). tpack
# embeds its version in the asset filename, so resolve the URL via
# the GitHub API rather than /releases/latest/download/.
set -euo pipefail

command -v tpack >/dev/null 2>&1 && exit 0

case "$(uname -m)" in
  x86_64)  arch="linux_amd64" ;;
  aarch64) arch="linux_arm64" ;;
  *) echo "unsupported arch for tpack: $(uname -m); skipping" >&2; exit 0 ;;
esac

mkdir -p "$HOME/.local/bin"
url=$(curl -sSfL https://api.github.com/repos/tmuxpack/tpack/releases/latest \
  | grep -oE '"browser_download_url": *"[^"]*'"${arch}"'\.tar\.gz"' \
  | head -1 \
  | sed -E 's/.*"(https:[^"]+)"/\1/')
if [[ -z "$url" ]]; then
  echo "could not resolve tpack release for $arch; skipping" >&2
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "$url" | tar xz -C "$tmp"
mv "$tmp/tpack" "$HOME/.local/bin/tpack"
chmod +x "$HOME/.local/bin/tpack"

# Fetch the plugins declared in .config/tmux/tmux.conf so a fresh
# machine doesn't drop into tmux with no theme until the user
# remembers to hit `prefix + I`.
if command -v tmux >/dev/null 2>&1; then
  "$HOME/.local/bin/tpack" install >/dev/null 2>&1 \
    || echo "tpack install failed; run it manually" >&2
fi
