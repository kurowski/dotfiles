#!/usr/bin/env bash
# neovim, straight from upstream on every platform. This started life as
# a Debian workaround (trixie ships 0.10, AstroNvim needs >= 0.11), but
# no package manager here is reliably current — so don't settle for
# whatever dnf or brew happens to have either. Installs under
# ~/.local/nvim, symlinked into ~/.local/bin (ahead of /usr/bin on PATH
# per .zshrc), so it wins over any distro copy still lying around.
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)  asset="nvim-linux-x86_64" ;;
  Linux_aarch64) asset="nvim-linux-arm64" ;;
  Darwin_x86_64) asset="nvim-macos-x86_64" ;;
  Darwin_arm64)  asset="nvim-macos-arm64" ;;
  *) echo "unsupported os/arch for neovim: $(uname -sm); skipping" >&2; exit 0 ;;
esac

prefix="$HOME/.local/nvim"
latest=$(latest_release neovim/neovim) || {
  echo "could not resolve latest neovim release; skipping" >&2; exit 0
}
[[ "$(current_version "$prefix/bin/nvim" --version)" == "$latest" ]] && exit 0

# A whole tree rather than a lone binary, so this unpacks by hand
# instead of using install_from_tarball. Extract fully before touching
# the live prefix, so a failed download leaves the old nvim working.
#
# (The `xattr -c` in neovim's macOS install instructions is for browser
# downloads — curl doesn't set the quarantine attribute.)
mkdir -p "$HOME/.local/bin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "https://github.com/neovim/neovim/releases/download/v${latest}/${asset}.tar.gz" \
  | tar xz -C "$tmp"
rm -rf "$prefix"
mv "$tmp/$asset" "$prefix"
ln -snf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
