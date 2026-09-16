#!/usr/bin/env bash
# asdbctl — brightness control for the Apple Studio Display. The display
# answers no DDC/CI, so ddcutil (in the base Fedora list, for every other
# monitor here) can't see it at all; brightness rides a USB HID feature
# report instead, which is what asdbctl writes.
#
# Host-scoped because it's hardware, not profile — the same reason fprintd
# sits in hosts/uceap-dev01.toml rather than the base Fedora list. This is
# the first scripts.tag-<hostname>/ directory; the short hostname is an
# auto-derived tag like any other, so the AND rule and gating work the same
# as scripts.tag-personal/. The Mac is the only other machine that meets
# this display, and macOS drives its brightness natively.
#
# Built from source: upstream publishes no prebuilt binaries for any
# platform, so lib/upstream.bash's tarball path doesn't apply here — only
# its release lookup does.
set -euo pipefail

# upstream.bash lives beside the untagged scripts; this one is gated by its
# directory, so reach across rather than through $HM_REPO — same reasoning
# as scripts.tag-personal/26-music-assistant.sh.
# shellcheck source=../scripts/lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/upstream.bash"

# The udev rule first, so it lands even if the build below fails. Nothing
# about it depends on the binary, or on the display being plugged in.
#
# hidraw nodes are root-only on Fedora (crw------- across the board), which
# would leave asdbctl needing sudo for every keypress. This is upstream's
# rules.d file verbatim, all three product IDs: the 2022 Studio Display
# (0x1114) is the one on this desk, and 1.1.0 added the two 2026 models.
# TAG+="uaccess" rather than a group is what hands the node to whoever holds
# the local seat, so it follows the login session instead of needing a
# supplementary group.
rules=/etc/udev/rules.d/20-asd-backlight.rules
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<'RULES'
SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1114", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1116", MODE="0660", TAG+="uaccess"
SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="05ac", ATTRS{idProduct}=="1118", MODE="0660", TAG+="uaccess"
RULES

# Compare before writing so a re-apply doesn't prompt for sudo on a host
# that's already correct. The trigger re-runs the rule against the display
# that's already attached, so there's no replug or reboot to remember.
if ! cmp -s "$tmp" "$rules"; then
  sudo install -m 0644 "$tmp" "$rules"
  sudo udevadm control --reload
  sudo udevadm trigger --subsystem-match=hidraw
fi

# cargo may not be on PATH in a non-login script environment.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
command -v cargo >/dev/null 2>&1 || { echo "asdbctl: cargo not found, skipping" >&2; exit 0; }

latest=$(latest_release juliuszint/asdbctl) || {
  echo "could not resolve latest asdbctl release; skipping" >&2; exit 0
}

# Not current_version: asdbctl's clap builder sets no .version(), so the
# binary itself can't be asked what it is. cargo's own record can —
# `install --list` is a documented flag and reads $CARGO_HOME metadata, so
# it costs no second network round-trip. That keeps this on the same
# resolve-compare-no-op shape as the release-tarball scripts instead of the
# install-once guard in 19-zsh-patina.sh, which would have frozen the host
# at whatever version it was provisioned with — and 1.1.0 was the release
# that taught asdbctl the 2026 displays.
installed=$(cargo install --list 2>/dev/null | sed -n 's/^asdbctl v\([0-9][^ :]*\).*/\1/p' || true)
[[ "$installed" == "$latest" ]] && exit 0

# --tag, not the default branch, so what's installed is the version just
# compared. hidapi builds its bundled hidraw backend against libudev, hence
# systemd-devel in hosts/uceap-dev01.toml.
cargo install --locked --git https://github.com/juliuszint/asdbctl --tag "v$latest"
