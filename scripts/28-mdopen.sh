#!/usr/bin/env bash
# mdopen — renders markdown locally and hands it to the browser as a
# read-only preview (`mdopen README.md`, live-reloading with --reload).
# Picked over grip, the obvious alternative, because grip POSTs the file to
# GitHub's /markdown API: your content leaves the box, you get 60 requests
# an hour unauthenticated, and it inlines the whole of GitHub's CSS for a
# 3.3MB page where this one is 15KB. Built via cargo; rustup is provisioned
# by 01-rust-toolchain.sh.
#
# Desktop-scoped: the entire job is opening a browser, which a headless host
# hasn't got. Gating on cargo instead wouldn't do — 01-rust-toolchain.sh
# skips only containers, so the servers have a toolchain too.
#
# No version compare, unlike the release-tarball scripts: `cargo install`
# resolves the registry itself and no-ops with "already installed" once the
# crate is current, so it upgrades in place when a release lands. Same trade
# 17-devcontainer-cli.sh makes with npm, minus the probe — there the probe
# buys something, here the check and the install are the same round-trip.
#
# Nothing to configure on the typography side, which is the reason to reach
# for this over a terminal renderer: mdopen's stylesheet sets no font-family
# at all, so the body font is whatever the browser defaults to. That's a
# browser setting, not a dotfile.
set -euo pipefail

case ",$HM_TAGS," in *,desktop,*) ;; *) exit 0 ;; esac

# cargo may not be on PATH in a non-login script environment.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
command -v cargo >/dev/null 2>&1 || { echo "mdopen: cargo not found, skipping" >&2; exit 0; }

cargo install --locked mdopen
