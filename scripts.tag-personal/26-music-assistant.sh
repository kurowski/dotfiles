#!/usr/bin/env bash
# Music Assistant desktop companion. Not in Fedora, not on Flathub, no
# COPR — upstream publishes a per-release rpm and deb on GitHub and
# nothing is watching those for new versions. So this follows the same
# shape as the upstream-binary scripts: resolve the newest release,
# compare it to what's installed, no-op when they match. `hm apply`
# carries the upgrades instead of freezing the app at whatever version
# the host was provisioned with.
#
# The app does ship Tauri's self-updater, but its Linux payloads are
# AppImage-only — `latest.json` in the release lists linux-x86_64-appimage
# and linux-aarch64-appimage and no native-package target — so an rpm or
# deb install can't consume them. Taking the native package anyway is the
# trade: it brings its own .desktop entry and hicolor icons, which an
# AppImage dropped in ~/.local/bin would leave us hand-writing, and this
# script stands in for the self-update it gives up.
#
# Arch has it in the AUR, which paru already keeps current, so it's
# declared in 00-aur-packages.sh instead — same split as 1Password and
# VS Code.
set -euo pipefail

# upstream.bash lives beside the untagged scripts; this one is gated by
# its directory, so reach across rather than through $HM_REPO — same
# reasoning as the comment in the lib itself, just one level further out.
# shellcheck source=../scripts/lib/upstream.bash
. "$(dirname "${BASH_SOURCE[0]}")/../scripts/lib/upstream.bash"

has_tag() { case ",$HM_TAGS," in *,"$1",*) return 0 ;; *) return 1 ;; esac; }

has_tag desktop || exit 0

latest=$(latest_release music-assistant/desktop-app) || {
  echo "could not resolve latest Music Assistant release; skipping" >&2
  exit 0
}

# Upstream tags releases bare (0.6.2, no leading v), and latest_release
# strips a "v" that isn't there — so $latest is both the tag and the
# version string the packages carry.
case "$(uname -m)" in
  x86_64)  rpm_arch=x86_64;  deb_arch=amd64 ;;
  aarch64) rpm_arch=aarch64; deb_arch=arm64 ;;
  *) echo "unsupported arch for Music Assistant: $(uname -m); skipping" >&2
     exit 0 ;;
esac

base="https://github.com/music-assistant/desktop-app/releases/download/${latest}"

# Both packages are named `music-assistant`; the binary they install is
# `music-assistant-companion`, which is why the version check queries the
# package manager rather than running the app with a --version flag.
if has_tag fedora; then
  [[ "$(current_version rpm -q music-assistant)" == "$latest" ]] && exit 0
  # The rpm's release field has been -1 for every build so far. If that
  # ever moves, the download 404s and dnf fails loudly — which beats
  # silently staying a version behind.
  sudo dnf install -y "${base}/Music.Assistant-${latest}-1.${rpm_arch}.rpm"
elif has_tag ubuntu || has_tag debian; then
  [[ "$(current_version dpkg-query -W music-assistant)" == "$latest" ]] && exit 0
  # apt won't take a URL the way dnf does, so stage the deb first. The
  # tempdir means a truncated download fails before apt sees it, leaving
  # the installed copy alone.
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  curl -sSfL -o "$tmp/music-assistant.deb" \
    "${base}/Music.Assistant_${latest}_${deb_arch}.deb"
  sudo apt-get install -y "$tmp/music-assistant.deb"
fi
