#!/usr/bin/env bash
# JetBrainsMono Nerd Font — not in Fedora repos (the distro's
# `jetbrains-mono-fonts` is the unpatched original). starship and
# ghostty need the Nerd-patched glyphs.
set -euo pipefail

font_dir="$HOME/.local/share/fonts/JetBrainsMono"
if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*.ttf" >/dev/null; then
  exit 0
fi

mkdir -p "$font_dir"
curl -sSfL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
  | tar xJ -C "$font_dir"
fc-cache -f "$font_dir" >/dev/null
