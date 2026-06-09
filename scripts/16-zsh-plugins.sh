#!/usr/bin/env bash
# Vendored source-only zsh plugins — no plugin manager. Cloned on first
# apply, fast-forwarded on later applies; sourced from .zshrc. Binaries
# (carapace, zsh-patina) and OS packages (zoxide) live in their own
# scripts / homie.toml. Pin a #ref below to freeze a plugin on a
# long-lived host; leave it off to track upstream HEAD.
set -euo pipefail

dir="$HOME/.zsh/plugins"
mkdir -p "$dir"

plugins=(
  "zsh-autosuggestions=https://github.com/zsh-users/zsh-autosuggestions"
  "fzf-tab=https://github.com/Aloxaf/fzf-tab"
)

for spec in "${plugins[@]}"; do
  name="${spec%%=*}"; rest="${spec#*=}"
  url="${rest%%#*}"; ref=""
  [[ "$rest" == *"#"* ]] && ref="${rest##*#}"
  dest="$dir/$name"
  if [[ -d "$dest/.git" ]]; then
    git -C "$dest" fetch --quiet --depth=1 origin "${ref:-HEAD}"
    git -C "$dest" checkout --quiet --detach FETCH_HEAD
  else
    git clone --quiet --depth=1 ${ref:+--branch "$ref"} "$url" "$dest"
  fi
done
