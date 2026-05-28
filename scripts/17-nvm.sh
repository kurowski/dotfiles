#!/usr/bin/env bash
# Ubuntu doesn't have a current-enough Node in apt; install NVM into
# ~/.nvm and grab Node 24. Fedora ships nodejs22 in dnf, so skip.
set -euo pipefail

case ",$HM_TAGS," in *,ubuntu,*|*,debian,*) ;; *) exit 0 ;; esac

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
