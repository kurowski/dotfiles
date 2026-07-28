#!/usr/bin/env bash
# tpack (tmux plugin manager, drop-in tpm replacement) — not in any
# distro repo. Grab the prebuilt binary from the upstream release and
# drop it in ~/.local/bin (on PATH via .zshrc).
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)   arch="linux_amd64" ;;
  Linux_aarch64)  arch="linux_arm64" ;;
  Darwin_x86_64)  arch="darwin_amd64" ;;
  Darwin_arm64)   arch="darwin_arm64" ;;
  *) echo "unsupported os/arch for tpack: $(uname -sm); skipping" >&2; exit 0 ;;
esac

bin="$HOME/.local/bin/tpack"
latest=$(latest_release tmuxpack/tpack) || {
  echo "could not resolve latest tpack release; skipping" >&2; exit 0
}
[[ "$(current_version "$bin" --version)" == "$latest" ]] && exit 0

# tpack embeds its version in the asset filename, which used to mean
# scraping the GitHub API for the download URL. The release tag we
# already resolved is that same string, so build the URL directly.
mkdir -p "$HOME/.local/bin"
install_from_tarball \
  "https://github.com/tmuxpack/tpack/releases/download/v${latest}/tpack_${latest}_${arch}.tar.gz" \
  tpack "$bin"

# Fetch the plugins declared in .config/tmux/tmux.conf so a fresh
# machine doesn't drop into tmux with no theme until the user
# remembers to hit `prefix + I`. A no-op once they're present, so it's
# fine that upgrades now come through here too.
if command -v tmux >/dev/null 2>&1; then
  "$bin" install >/dev/null 2>&1 || echo "tpack install failed; run it manually" >&2
fi
