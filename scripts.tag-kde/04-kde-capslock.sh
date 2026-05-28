#!/usr/bin/env bash
# Remap CapsLock to Escape via KDE's kxkbrc. Takes effect on next KDE
# session login. kwriteconfig6 is idempotent.
set -euo pipefail

command -v kwriteconfig6 >/dev/null 2>&1 || exit 0

kwriteconfig6 --file kxkbrc --group Layout --key Options "caps:escape"
