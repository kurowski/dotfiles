#!/usr/bin/env bash
# Fedora ships ffmpeg-free (limited codecs). On personal hosts where
# RPM Fusion's free repo is enabled, swap to full ffmpeg. No-op once
# the swap has happened.
set -euo pipefail

case ",$HM_TAGS," in *,personal,*) ;; *) exit 0 ;; esac
command -v rpm >/dev/null 2>&1 || exit 0

if rpm -q ffmpeg-free >/dev/null 2>&1 && ! rpm -q ffmpeg >/dev/null 2>&1; then
  sudo dnf swap -y --allowerasing ffmpeg-free ffmpeg
fi
