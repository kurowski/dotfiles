#!/usr/bin/env bash
# Rust toolchain, bootstrapped from upstream rustup-init like every
# other unmanaged binary here. Fedora's `rustup` package bootstraps one
# too, but it builds with self-update disabled — that copy can never
# move on its own, which is the exact drift this repo is trying to
# stop. --no-modify-path because .zshrc already adds ~/.cargo/bin.
#
# No version compare: rustup is its own updater, so once it's in place
# `rustup update` is the whole job. That's a network round-trip per
# apply, and a real download when a release lands.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac

case "$(uname -s)_$(uname -m)" in
  Linux_x86_64)  target="x86_64-unknown-linux-gnu" ;;
  Linux_aarch64) target="aarch64-unknown-linux-gnu" ;;
  Darwin_x86_64) target="x86_64-apple-darwin" ;;
  Darwin_arm64)  target="aarch64-apple-darwin" ;;
  *) echo "unsupported os/arch for rustup: $(uname -sm); skipping" >&2; exit 0 ;;
esac

rustup="$HOME/.cargo/bin/rustup"
replace=0

if [[ -x "$rustup" ]]; then
  # tee so the update still streams; the capture is only read below.
  out=$("$rustup" update 2>&1 | tee /dev/stderr) \
    || echo "rustup update failed; leaving toolchain as-is" >&2

  # A distro-built rustup announces itself here on every run. Match the
  # message rather than probing with `rustup self update` separately:
  # one round-trip, and a network failure can't be mistaken for it.
  grep -q 'self-update is disabled' <<<"$out" && replace=1
fi

if [[ ! -x "$rustup" || "$replace" == 1 ]]; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -sSfL "https://static.rust-lang.org/rustup/dist/${target}/rustup-init" \
    -o "$tmp/rustup-init" || {
      echo "could not fetch rustup-init; skipping" >&2; exit 0
    }
  chmod +x "$tmp/rustup-init"

  # Installing over an existing rustup is supported and needs no force
  # flag: it swaps the binary, leaves the ~/.cargo/bin shim farm and
  # the toolchains in ~/.rustup alone. Skip the default-toolchain
  # refresh on that path, since the update above just did it.
  args=(-y --default-toolchain stable --no-modify-path)
  (( replace )) && args+=(--no-update-default-toolchain)
  "$tmp/rustup-init" "${args[@]}"
fi
