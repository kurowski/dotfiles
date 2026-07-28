#!/usr/bin/env bash
# Debian trixie ships neovim 0.10, but AstroNvim needs >= 0.11. Pull
# the upstream prebuilt under ~/.local/nvim and symlink into
# ~/.local/bin (ahead of /usr/bin on PATH per .zshrc).
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case ",$HM_TAGS," in *,debian,*|*,ubuntu,*) ;; *) exit 0 ;; esac

case "$(uname -m)" in
  x86_64)  arch="linux-x86_64" ;;
  aarch64) arch="linux-arm64" ;;
  *) echo "unsupported arch for neovim: $(uname -m); skipping" >&2; exit 0 ;;
esac

prefix="$HOME/.local/nvim"
latest=$(latest_release neovim/neovim) || {
  echo "could not resolve latest neovim release; skipping" >&2; exit 0
}
[[ "$(current_version "$prefix/bin/nvim" --version)" == "$latest" ]] && exit 0

# A whole tree rather than a lone binary, so this unpacks by hand
# instead of using install_from_tarball. Extract fully before touching
# the live prefix, so a failed download leaves the old nvim working.
mkdir -p "$HOME/.local/bin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "https://github.com/neovim/neovim/releases/download/v${latest}/nvim-${arch}.tar.gz" \
  | tar xz -C "$tmp"
rm -rf "$prefix"
mv "$tmp/nvim-${arch}" "$prefix"
ln -snf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
