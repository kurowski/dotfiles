#!/usr/bin/env bash
# @devcontainers/cli has no standalone binary release; npm is the
# supported install path. --prefix lands it in ~/.local (on PATH)
# instead of writing to /usr with sudo.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac
command -v devcontainer >/dev/null 2>&1 && exit 0
command -v npm >/dev/null 2>&1 || exit 0

mkdir -p "$HOME/.local"
npm install -g --prefix "$HOME/.local" @devcontainers/cli
