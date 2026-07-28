#!/usr/bin/env bash
# Fedora ships `rustup` as just the bootstrapper; the real toolchain
# lands in ~/.cargo/bin after rustup-init. --no-modify-path because
# .zshrc already adds ~/.cargo/bin.
#
# rustup is its own updater, so unlike the release-tarball scripts this
# doesn't compare versions itself — it hands off to `rustup update`,
# which syncs the stable channel. That's a network round-trip on every
# apply (and a real download when a release lands), which is the price
# of not drifting a release or two behind.
#
# Only the toolchain, not rustup: rustup-init from Fedora's package
# builds with self-update disabled, so rustup itself tracks dnf. It
# says so on every run — that notice is expected, not a failure.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac

rustup="$HOME/.cargo/bin/rustup"

if [[ ! -x "$rustup" ]]; then
  command -v rustup-init >/dev/null 2>&1 || exit 0
  rustup-init -y --default-toolchain stable --no-modify-path
  exit 0
fi

# Don't fail the apply over a flaky network — the toolchain still works.
"$rustup" update || echo "rustup update failed; leaving toolchain as-is" >&2
