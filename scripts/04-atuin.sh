#!/usr/bin/env bash
# atuin — distro packages lag badly (Fedora 44 ships 18.12.1 against
# upstream's 18.18.1), and a shared sync server is happiest when every
# host speaks the same version. Take the prebuilt binary from the
# upstream release into ~/.local/bin (ahead of /usr/bin on PATH per
# .zshrc), so this wins even where a stale distro package lingers.
#
# Unlike the other upstream-binary scripts, this one upgrades in place
# rather than no-op'ing once the binary exists: staying current is the
# whole point. /releases/latest redirects to the tagged release, which
# gives the version without spending the GitHub API's unauthenticated
# rate limit on every apply.
set -euo pipefail

os_arch="$(uname -s)_$(uname -m)"
case "$os_arch" in
  Linux_x86_64)  target="x86_64-unknown-linux-gnu" ;;
  Linux_aarch64) target="aarch64-unknown-linux-gnu" ;;
  Darwin_x86_64) target="x86_64-apple-darwin" ;;
  Darwin_arm64)  target="aarch64-apple-darwin" ;;
  *) echo "unsupported os/arch for atuin: $os_arch; skipping" >&2; exit 0 ;;
esac

bin="$HOME/.local/bin/atuin"

# .../releases/latest → .../releases/tag/v18.18.1
url=$(curl -sSfL -o /dev/null -w '%{url_effective}' \
  https://github.com/atuinsh/atuin/releases/latest) || url=""
latest="${url##*/tag/v}"
if [[ -z "$latest" || "$latest" == "$url" ]]; then
  echo "could not resolve latest atuin release; skipping" >&2
  exit 0
fi

# `atuin --version` prints "atuin 18.18.1 (NO_GIT)".
if [[ -x "$bin" ]] && [[ "$("$bin" --version | awk '{print $2}')" == "$latest" ]]; then
  exit 0
fi

mkdir -p "$HOME/.local/bin"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
curl -sSfL "https://github.com/atuinsh/atuin/releases/download/v${latest}/atuin-${target}.tar.gz" \
  | tar xz -C "$tmp"
install -m 755 "$tmp/atuin-${target}/atuin" "$bin"
