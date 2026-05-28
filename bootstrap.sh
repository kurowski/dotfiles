#!/usr/bin/env bash
# Bootstrap script for kurowski/dotfiles.
#
# Run this on a fresh Fedora install:
#   curl -fsSL https://raw.githubusercontent.com/kurowski/dotfiles/main/bootstrap.sh | bash
#
# Flow:
#   1. Download the hm binary for this arch.
#   2. `hm bootstrap` installs git + ca-certificates so HTTPS clones
#      work and the next step plus all future `hm apply` runs can
#      reach GitHub.
#   3. Clone this repo and exec `hm apply`.
set -euo pipefail

# Devcontainers often start processes without a login session, so $USER
# is unset even though `id -un` knows the name. Normalize it here so
# every script hm spawns can rely on it.
export USER="${USER:-$(id -un)}"

REPO_URL="https://github.com/kurowski/dotfiles.git"
REPO_DIR="${HM_REPO:-$HOME/Projects/dotfiles}"
HM_RELEASE="${HM_RELEASE:-latest}"

arch="$(uname -m)"
case "$arch" in
  x86_64)        arch=amd64 ;;
  aarch64|arm64) arch=arm64 ;;
  *) echo "Unsupported architecture: $arch" >&2; exit 1 ;;
esac

if [ "$(id -u)" = "0" ]; then
  bindir=/usr/local/bin
else
  bindir="$HOME/.local/bin"
  mkdir -p "$bindir"
fi

if ! command -v hm >/dev/null 2>&1; then
  if [ "$HM_RELEASE" = "latest" ]; then
    base="https://github.com/kurowski/homie/releases/latest/download"
  else
    base="https://github.com/kurowski/homie/releases/download/${HM_RELEASE}"
  fi
  binary="hm-linux-${arch}"
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' EXIT

  echo "Downloading ${base}/${binary}"
  curl -fsSL "$base/$binary"     -o "$tmp/$binary"
  curl -fsSL "$base/SHA256SUMS"  -o "$tmp/SHA256SUMS"

  ( cd "$tmp" && sha256sum -c --ignore-missing SHA256SUMS )

  install -m 0755 "$tmp/$binary" "$bindir/hm"
  export PATH="$bindir:$PATH"
fi

hm bootstrap

if [ ! -d "$REPO_DIR/.git" ]; then
  echo "Cloning ${REPO_URL} -> ${REPO_DIR}"
  mkdir -p "$(dirname "$REPO_DIR")"
  git clone "$REPO_URL" "$REPO_DIR"
fi

cd "$REPO_DIR"
exec hm apply
