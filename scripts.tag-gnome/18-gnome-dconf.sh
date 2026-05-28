#!/usr/bin/env bash
# Apply GNOME desktop settings via dconf. Mirrors roles/gnome from the
# Ansible repo. dconf writes are idempotent — same value = no change.
set -euo pipefail

command -v dconf >/dev/null 2>&1 || exit 0

w() { dconf write "$1" "$2"; }

# --- Input ---
w /org/gnome/desktop/input-sources/xkb-options "['caps:escape']"
w /org/gnome/desktop/peripherals/mouse/natural-scroll "true"
w /org/gnome/desktop/peripherals/touchpad/two-finger-scrolling-enabled "true"

# --- Appearance ---
if [[ "${THEME:-dark}" == "dark" ]]; then
  w /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
  w /org/gnome/desktop/interface/gtk-theme "'Yaru-dark'"
  w /org/gnome/desktop/interface/icon-theme "'Yaru-dark'"
else
  w /org/gnome/desktop/interface/color-scheme "'default'"
  w /org/gnome/desktop/interface/gtk-theme "'Yaru'"
  w /org/gnome/desktop/interface/icon-theme "'Yaru'"
fi
w /org/gnome/desktop/interface/font-antialiasing "'rgba'"
w /org/gnome/desktop/interface/font-hinting "'slight'"

# --- Terminal (Ptyxis) ---
w /org/gnome/Ptyxis/font-name "'JetBrainsMono Nerd Font Mono 10'"
w /org/gnome/Ptyxis/use-system-font "false"

# --- Window management ---
w /org/gnome/mutter/dynamic-workspaces "false"
w /org/gnome/desktop/wm/preferences/num-workspaces "1"
w /org/gnome/desktop/wm/preferences/auto-raise "true"
w /org/gnome/desktop/wm/preferences/focus-mode "'click'"
w /org/gnome/mutter/edge-tiling "false"
w /org/gnome/mutter/keybindings/toggle-tiled-left "@as []"
w /org/gnome/mutter/keybindings/toggle-tiled-right "@as []"

# --- Tiling Assistant extension ---
w /org/gnome/shell/extensions/tiling-assistant/focus-hint-color "'rgb(203,67,20)'"
w /org/gnome/shell/extensions/tiling-assistant/tiling-popup-all-workspace "true"

# --- Dock (dash-to-dock) ---
w /org/gnome/shell/extensions/dash-to-dock/extend-height "false"
w /org/gnome/shell/extensions/dash-to-dock/dash-max-icon-size "44"
w /org/gnome/shell/extensions/dash-to-dock/dock-fixed "false"
w /org/gnome/shell/extensions/dash-to-dock/show-mounts "false"
w /org/gnome/shell/extensions/dash-to-dock/show-trash "false"

# Dock favorites — personal default; future work GNOME hosts would
# need a host-overlay-driven list (not modeled yet).
if case ",$HM_TAGS," in *,personal,*) true ;; *) false ;; esac; then
  w /org/gnome/shell/favorite-apps "['org.gnome.Nautilus.desktop', '1password.desktop', 'md.obsidian.Obsidian.desktop', 'com.mitchellh.ghostty.desktop', 'firefox.desktop', 'code_code.desktop', 'spotify_spotify.desktop', 'snap-store_snap-store.desktop']"
fi

# --- Desktop icons ---
w /org/gnome/shell/extensions/ding/show-home "false"

# --- Power ---
w /org/gnome/settings-daemon/plugins/power/power-button-action "'nothing'"
w /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-timeout "3600"
w /org/gnome/settings-daemon/plugins/power/sleep-inactive-ac-type "'nothing'"
w /org/gnome/desktop/session/idle-delay "uint32 900"

# --- File chooser ---
w /org/gtk/gtk4/settings/file-chooser/sort-directories-first "true"
w /org/gtk/settings/file-chooser/sort-directories-first "true"
