#!/usr/bin/env zsh
# Shared helpers for the dc* devcontainer scripts. Sourced via
# `${0:A:h}/.dc-common.sh` from each, where :A resolves the symlink in
# ~/.local/bin back to this file in the dotfiles repo.

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
