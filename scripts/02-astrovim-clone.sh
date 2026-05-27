#!/usr/bin/env bash
# Bootstrap AstroNvim. Homie's home phase has already dropped our
# colorscheme/community.lua symlinks into ~/.config/nvim/, so a plain
# `git clone` would refuse the non-empty target. Instead, clone to a
# tempdir, copy in the template files Homie didn't already symlink,
# then move the .git in so future `git pull` works.
set -euo pipefail

if [[ -d "$HOME/.config/nvim/.git" ]]; then
  exit 0
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
git clone --depth=1 https://github.com/AstroNvim/template "$tmp/nvim"

mkdir -p "$HOME/.config/nvim"
(cd "$tmp/nvim" && tar -c --exclude=.git .) \
  | (cd "$HOME/.config/nvim" && tar -x --keep-old-files 2>/dev/null || true)
mv "$tmp/nvim/.git" "$HOME/.config/nvim/.git"
