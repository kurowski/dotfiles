#!/usr/bin/env bash
# Switch the user's login shell to zsh.
set -euo pipefail

# macOS ships zsh as the default login shell already.
case ",$HM_TAGS," in *,macos,*) exit 0 ;; esac

target=/usr/bin/zsh
[[ -x "$target" ]] || exit 0
[[ "$(getent passwd "$USER" | cut -d: -f7)" == "$target" ]] && exit 0

sudo chsh -s "$target" "$USER"
