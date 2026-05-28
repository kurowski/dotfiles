#!/usr/bin/env bash
# Ubuntu's ghostty package doesn't ship the `xterm-ghostty` terminfo
# entry that ghostty sets as TERM. ncurses-term provides the base
# `ghostty` entry; alias it so curses apps and remote sshd find it.
set -euo pipefail

case ",$HM_TAGS," in *,debian,*|*,ubuntu,*) ;; *) exit 0 ;; esac
[[ -f /usr/share/terminfo/g/ghostty ]] || exit 0
[[ -f /usr/share/terminfo/x/xterm-ghostty ]] && exit 0

sudo install -m 0644 /usr/share/terminfo/g/ghostty /usr/share/terminfo/x/xterm-ghostty
