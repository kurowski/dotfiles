#!/usr/bin/env bash
# Generate zsh completions for tools that ship a generator but DON'T drop a
# completion file into fpath. Cached into ~/.zsh/completions (added to fpath
# in .zshrc) so compinit loads them with zero shell-startup cost — unlike a
# per-startup `eval "$(tool completion)"`. Regenerated every apply.
#
# Tools already covered by zsh's bundled completions are intentionally
# omitted: git, ssh, tmux, make, bat, fd, rg, eza, fzf, jq, npm, pip, podman,
# rclone, yt-dlp, glow, ghostty, systemctl, gpg, flatpak, ... (`print -l
# $fpath` + `ls */\_*` to audit). aws is wired directly in .zshrc (it uses a
# bash-style dynamic completer, not a static compdef file).
set -euo pipefail

dir="$HOME/.zsh/completions"
mkdir -p "$dir"

# cargo/rustup live under ~/.cargo (provisioned by 01-rust-toolchain.sh) and
# opencode under ~/.opencode/bin (installed outside homie) — neither is
# guaranteed on PATH in a non-login script env.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -d "$HOME/.opencode/bin" ]] && PATH="$HOME/.opencode/bin:$PATH"

# gen <outfile> <cmd...> — write only if the generator produced something, so
# a flaky/again-prompting tool never truncates a good cached file.
gen() {
  local out="$dir/$1"; shift
  if "$@" >"$out.tmp" 2>/dev/null && [[ -s "$out.tmp" ]] && head -1 "$out.tmp" | grep -q '#compdef'; then
    mv "$out.tmp" "$out"
  else
    rm -f "$out.tmp"
  fi
}

command -v gh        >/dev/null 2>&1 && gen _gh        gh completion -s zsh
command -v docker    >/dev/null 2>&1 && gen _docker    docker completion zsh
command -v op        >/dev/null 2>&1 && gen _op        op completion zsh
command -v tailscale >/dev/null 2>&1 && gen _tailscale tailscale completion zsh
command -v starship  >/dev/null 2>&1 && gen _starship  starship completions zsh
command -v opencode  >/dev/null 2>&1 && gen _opencode  opencode completion zsh
if command -v rustup >/dev/null 2>&1; then
  gen _rustup rustup completions zsh
  command -v cargo >/dev/null 2>&1 && gen _cargo rustup completions zsh cargo
fi

# Completions just changed → drop the daily-cached dump so the next shell
# rebuilds and picks them up immediately (see the compinit block in .zshrc).
rm -f "$HOME"/.zcompdump*
