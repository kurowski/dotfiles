#!/usr/bin/env bash
# Creative Pebble X Plus: park the hardware volume at max.
#
# home.tag-coach/.config/wireplumber/wireplumber.conf.d/51-creative-pebble-soft-mixer.conf
# takes volume away from the speakers' own mixer, because the firmware mutes
# the amp once that mixer drops below about -25.5 dB — 37% on the desktop
# slider. With PipeWire doing volume in software it never touches the hardware
# level again, so something has to leave that level at max once. Fedora's
# alsactl state daemon then stores it in /var/lib/alsa/asound.state, and udev
# restores it from there on every boot and replug.
#
# Order matters: the hardware level may only move once the *running*
# WirePlumber has the device in soft-mixer mode. While it still owns the mixer,
# an external jump to 100% is read straight back as the slider going to 100%.
# So if the rule is linked but not live yet, restart WirePlumber first — the
# same brief audio gap the rule needs anyway.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac
command -v amixer >/dev/null 2>&1 || exit 0
command -v pw-dump >/dev/null 2>&1 || exit 0
command -v systemctl >/dev/null 2>&1 || exit 0

# Speakers plugged in? The first line of each /proc/asound/cards entry starts
# with the card index; the continuation line doesn't.
card=$(awk '/^ *[0-9]+ \[/ && /Creative Pebble X Plus/ { print $1; exit }' /proc/asound/cards)
[[ -n "$card" ]] || exit 0

# Nothing to do without a session: no WirePlumber to check, and no one
# listening. The level is restored by udev regardless.
systemctl --user is-active --quiet wireplumber.service || exit 0

# amixer's sset is idempotent, but reading first keeps a no-op apply from
# poking the mixer at all.
amixer -c "$card" sget PCM | grep -q '\[100%\]' && exit 0

# The device object's props carry both its name and the rule's property, so
# look for the two inside one brace-delimited block, in either order.
soft_mixer_live() {
  pw-dump 2>/dev/null | tr -d ' \n' | grep -qE \
    'Creative_Pebble_X_Plus[^}]*"api\.alsa\.soft-mixer":true|"api\.alsa\.soft-mixer":true[^}]*Creative_Pebble_X_Plus'
}

rule="$HOME/.config/wireplumber/wireplumber.conf.d/51-creative-pebble-soft-mixer.conf"
if ! soft_mixer_live; then
  [[ -e "$rule" ]] || { echo "pebble soft-mixer rule not applied yet; skipping" >&2; exit 0; }
  systemctl --user restart wireplumber.service
  for _ in $(seq 1 20); do
    soft_mixer_live && break
    sleep 0.5
  done
  if ! soft_mixer_live; then
    echo "wireplumber restarted but the Pebble is still on its hardware mixer; leaving the level alone" >&2
    exit 1
  fi
fi

amixer -q -c "$card" sset PCM 100% unmute
