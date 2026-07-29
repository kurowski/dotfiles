#!/usr/bin/env bash
# Flatpak permissions the apps' own manifests don't grant.
#
# Obsidian: the Flathub build requests sockets=x11 only, and its launcher picks a
# backend by testing whether the Wayland socket is visible *inside* the sandbox.
# Without this override that test fails and it always lands on
# --ozone-platform=x11, which costs live light/dark switching: on the X11 backend
# Electron hears about theme changes through XSettings, and KDE runs no XSettings
# manager — it propagates to GTK by writing gtk-{3,4}.0/settings.ini and
# gsettings, which GTK reads only at startup. So Obsidian's own "Adapt to system"
# stayed frozen at whatever the mode was when it launched.
#
# With the socket granted the launcher takes its Wayland branch, and Chromium
# reads org.freedesktop.appearance color-scheme from the XDG portal instead — the
# same setting theme-mode watches, signalled on change. So Obsidian follows for
# free and nothing has to push to it.
#
# One consequence lives in home.tag-kde/.config/kwinrulesrc: a Wayland surface
# has no WM_WINDOW_ROLE, so a kwin rule that matches on windowrole silently
# stops applying. The Obsidian rule matches on wmclass alone for that reason.
set -euo pipefail

command -v flatpak >/dev/null 2>&1 || exit 0

# Desktop hosts only, and never macOS: there Obsidian is a brew cask and flatpak
# doesn't exist at all.
case ",$HM_TAGS," in
  *,macos,*) exit 0 ;;
  *,desktop,*) ;;
  *) exit 0 ;;  # servers: no flatpak apps
esac

# Idempotent, and deliberately safe to run before the app is installed: a --user
# override is just a keyfile named after the app id, written whether or not that
# app exists yet. So this needn't be ordered after the flatpak install phase.
flatpak override --user --socket=wayland md.obsidian.Obsidian
