#!/usr/bin/env bash
# @devcontainers/cli has no standalone binary release; npm is the
# supported install path. --prefix lands it in ~/.local (on PATH)
# instead of writing to /usr with sudo.
#
# Same upgrade-in-place shape as the release-tarball scripts, but the
# registry plays the part of latest_release here — `npm install -g`
# always fetches the newest version, so all this decides is whether
# it's worth the ~10s of running it.
set -euo pipefail

case ",$HM_TAGS," in *,container,*) exit 0 ;; esac
command -v npm >/dev/null 2>&1 || exit 0

bin="$HOME/.local/bin/devcontainer"
latest=$(npm view @devcontainers/cli version 2>/dev/null) || latest=""
if [[ -z "$latest" ]]; then
  echo "could not resolve latest @devcontainers/cli version; skipping" >&2
  exit 0
fi
[[ -x "$bin" && "$("$bin" --version 2>/dev/null)" == "$latest" ]] && exit 0

mkdir -p "$HOME/.local"
npm install -g --prefix "$HOME/.local" @devcontainers/cli
