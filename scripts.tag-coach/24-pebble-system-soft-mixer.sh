#!/usr/bin/env bash
# Creative Pebble X Plus: install the soft-mixer rule system-wide too.
#
# home.tag-coach/.config/wireplumber/wireplumber.conf.d/51-creative-pebble-soft-mixer.conf
# only reaches *my* WirePlumber. The Plasma Login greeter runs its own
# PipeWire + WirePlumber as the plasmalogin user from boot until someone logs
# in, and that instance sees the Pebble as an ordinary hardware-volume device
# it has never met — so it sets the speakers' own mixer to WirePlumber's
# default new-device volume, 0.4³ ≈ -24 dB. The alsactl state daemon
# dutifully saves that, and from then on 100% on the desktop slider sounds like
# a third of it. (First seen on the first reboot after the rule went in.)
#
# A copy in /etc/wireplumber/wireplumber.conf.d/ is read by every WirePlumber
# on the machine, greeter included, so none of them touches the hardware level
# and 25-pebble-hw-volume.sh's max stays put. A copy, not a symlink: the
# greeter user can't read into my home directory. The rule matches only the
# Pebble, so nothing else in the system session changes.
#
# Runs before 25-pebble-hw-volume.sh so a fresh apply fixes the cause before
# it repairs the symptom.
set -euo pipefail

case ",${HOMIE_TAGS:-}," in *,container,*) exit 0 ;; esac

# Reach across from the script rather than through $HOMIE_REPO, so this still
# runs when invoked by hand.
src="$(dirname "${BASH_SOURCE[0]}")/../home.tag-coach/.config/wireplumber/wireplumber.conf.d/51-creative-pebble-soft-mixer.conf"
dst=/etc/wireplumber/wireplumber.conf.d/51-creative-pebble-soft-mixer.conf

[[ -f "$src" ]] || exit 0
[[ -d /usr/share/wireplumber ]] || exit 0

cmp -s "$src" "$dst" && exit 0

# Takes effect for the greeter on the next boot; the running user session
# already has the rule through the home-directory copy.
sudo install -D -m 0644 "$src" "$dst"
