#!/usr/bin/env bash
# starship — not in Fedora's default repos. Take the prebuilt binary
# from the upstream release into ~/.local/bin (on PATH per .zshrc).
#
# This used to pipe starship.rs/install.sh, which can only install, not
# tell us whether an upgrade is due — so pair it with the release tag
# and it would re-download on every apply. Unpacking the asset directly
# is the same work the installer does, minus the guesswork.
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)  target="x86_64-unknown-linux-gnu" ;;
  # upstream publishes no gnu build for arm64 linux
  Linux_aarch64) target="aarch64-unknown-linux-musl" ;;
  Darwin_x86_64) target="x86_64-apple-darwin" ;;
  Darwin_arm64)  target="aarch64-apple-darwin" ;;
  *) echo "unsupported os/arch for starship: $(uname -sm); skipping" >&2; exit 0 ;;
esac

bin="$HOME/.local/bin/starship"
latest=$(latest_release starship/starship) || {
  echo "could not resolve latest starship release; skipping" >&2; exit 0
}
[[ "$(current_version "$bin" --version)" == "$latest" ]] && exit 0

mkdir -p "$HOME/.local/bin"
install_from_tarball \
  "https://github.com/starship/starship/releases/download/v${latest}/starship-${target}.tar.gz" \
  starship "$bin"
