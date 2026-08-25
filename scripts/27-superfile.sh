#!/usr/bin/env bash
# superfile (the `spf` TUI file manager) — in no distro repo here (not in
# Fedora's, not in Homebrew core), so take the prebuilt binary from the
# upstream release into ~/.local/bin (ahead of /usr/bin on PATH per .zshrc).
#
# The vim-like hotkeys live in .config/superfile/hotkeys.toml, symlinked by
# Homie's home phase — see the header there for why it's vendored.
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)  target="linux-amd64" ;;
  Linux_aarch64) target="linux-arm64" ;;
  Darwin_x86_64) target="darwin-amd64" ;;
  Darwin_arm64)  target="darwin-arm64" ;;
  *) echo "unsupported os/arch for superfile: $(uname -sm); skipping" >&2; exit 0 ;;
esac

bin="$HOME/.local/bin/spf"
latest=$(latest_release yorukot/superfile) || {
  echo "could not resolve latest superfile release; skipping" >&2; exit 0
}
[[ "$(current_version "$bin" --version)" == "$latest" ]] && exit 0

# superfile embeds the version in both the asset name and the directory
# inside the tarball, and splits the target either side of it —
# superfile-linux-v1.6.0-amd64/. Hence the reassembly rather than a plain
# "${target}" on both halves.
asset="superfile-${target%-*}-v${latest}-${target#*-}"
mkdir -p "$HOME/.local/bin"
install_from_tarball \
  "https://github.com/yorukot/superfile/releases/download/v${latest}/${asset}.tar.gz" \
  "dist/${asset}/spf" "$bin"
