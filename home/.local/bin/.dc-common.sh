#!/usr/bin/env zsh
# Shared helpers for the dc* devcontainer scripts. Sourced via
# `${0:A:h}/.dc-common.sh` from each, where :A resolves the symlink in
# ~/.local/bin back to this file in the dotfiles repo.

# Guard: if no sub-config was given and no default .devcontainer/devcontainer.json
# exists, look for sub-configs and print suggestions, then exit 1.
_dc_check_sub() {
  local cmd="$1" sub="$2"
  [[ -n "$sub" || -f .devcontainer/devcontainer.json ]] && return 0
  local subs=()
  for f in .devcontainer/*/devcontainer.json(N); do
    subs+=("${${f%/devcontainer.json}#.devcontainer/}")
  done
  if (( ${#subs[@]} > 0 )); then
    print -ru2 -- "$cmd: no default config at .devcontainer/devcontainer.json"
    print -ru2 -- ""
    print -ru2 -- "did you mean:"
    print -ru2 -- ""
    for s in "${subs[@]}"; do
      print -ru2 -- "    $cmd $s"
    done
    exit 1
  fi
}

# Canonical compose project name: <workspace>_<configdir-sans-dot>, lowercased
# and stripped of any chars outside [-_a-z0-9] (matches the devcontainer CLI's
# own Rg sanitization). Forces a stable, unique name — otherwise compose
# defaults to basename(compose-dir), which collides across repos for common
# subdir names like "portal".
_dc_project_name() {
  local sub="$1"
  local cfg="${sub:-devcontainer}"
  cfg="${cfg#.}"
  local name="$(basename "$PWD")_${cfg}"
  echo "$name" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]_-'
}
