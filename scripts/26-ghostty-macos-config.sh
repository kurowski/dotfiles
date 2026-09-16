#!/usr/bin/env bash
# On macOS ghostty reads ~/Library/Application Support/com.mitchellh.ghostty/
# config *in addition to* the XDG one, and later wins — so anything left in
# there silently overrides the homie-managed config key by key. ghostty writes
# that file itself, as a commented template, the first time it starts without
# finding a config, which on a fresh Mac is before homie has ever run. Whatever
# you then set in it (a theme picked from the UI, say) outlives the apply and
# there's no sign of it in this repo.
#
# So: move it aside once, and keep removing it if ghostty writes it again. The
# XDG config stays the only place terminal settings live.
set -euo pipefail

case ",$HOMIE_TAGS," in *,macos,*) ;; *) exit 0 ;; esac

native="$HOME/Library/Application Support/com.mitchellh.ghostty/config"
[[ -e "$native" ]] || exit 0

# Only safe because the XDG config is the one ghostty will be left with.
xdg="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty/config"
[[ -e "$xdg" ]] || { echo "no $xdg yet; leaving ghostty's own config alone" >&2; exit 0; }

# First run keeps a copy, in case the file held something worth carrying over
# into the template. After that there's nothing new to save — it's ghostty's
# own boilerplate again.
if [[ ! -e "$native.pre-homie" ]]; then
  mv "$native" "$native.pre-homie"
  echo "moved ghostty's macOS config to $native.pre-homie (it was overriding ~/.config/ghostty/config)"
else
  rm "$native"
  echo "removed ghostty's regenerated macOS config; $xdg stands"
fi
