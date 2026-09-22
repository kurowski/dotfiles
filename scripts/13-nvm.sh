#!/usr/bin/env bash
# Ubuntu/Debian's apt and Fedora's dnf never have a current-enough Node —
# Fedora's own package is versioned per major (nodejs22, nodejs24, ...) and
# drifts out of date here every time Fedora rotates its default. Install
# NVM into ~/.nvm and grab Node 24 instead. Arch ships a current nodejs in
# extra, so it skips.
# The Node version is pinned deliberately — this is a Node *version
# manager*, so tracking upstream is `nvm install`'s job, not homie's.
set -euo pipefail

case ",$HOMIE_TAGS," in *,ubuntu,*|*,debian,*|*,fedora,*) ;; *) exit 0 ;; esac

NVM_VERSION="v0.40.3"
NVM_DIR="$HOME/.nvm"

if [[ ! -s "$NVM_DIR/nvm.sh" ]]; then
  mkdir -p "$NVM_DIR"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" \
    | PROFILE=/dev/null bash
fi

# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

if ! nvm ls 24 >/dev/null 2>&1; then
  nvm install 24
fi
