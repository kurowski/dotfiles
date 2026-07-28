#!/usr/bin/env bash
# atuin — distro packages lag badly (Fedora 44 ships 18.12.1 against
# upstream's 18.18.1), and a shared sync server is happiest when every
# host speaks the same version. Take the prebuilt binary from the
# upstream release into ~/.local/bin (ahead of /usr/bin on PATH per
# .zshrc), so this wins even where a stale distro package lingers.
set -euo pipefail

# shellcheck source=lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/lib/upstream.bash"

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)  target="x86_64-unknown-linux-gnu" ;;
  Linux_aarch64) target="aarch64-unknown-linux-gnu" ;;
  Darwin_x86_64) target="x86_64-apple-darwin" ;;
  Darwin_arm64)  target="aarch64-apple-darwin" ;;
  *) echo "unsupported os/arch for atuin: $(uname -sm); skipping" >&2; exit 0 ;;
esac

bin="$HOME/.local/bin/atuin"
latest=$(latest_release atuinsh/atuin) || {
  echo "could not resolve latest atuin release; skipping" >&2; exit 0
}
[[ "$(current_version "$bin" --version)" == "$latest" ]] && exit 0

mkdir -p "$HOME/.local/bin"
install_from_tarball \
  "https://github.com/atuinsh/atuin/releases/download/v${latest}/atuin-${target}.tar.gz" \
  "atuin-${target}/atuin" "$bin"
