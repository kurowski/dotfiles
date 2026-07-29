#!/usr/bin/env bash
# Point GTK, Qt, icons and cursors at Catppuccin for the Hyprland session.
#
# Plasma does all of this itself through its own settings modules, which is why
# none of it existed before. Outside Plasma each toolkit has to be told
# separately, and each one reads a different file.
#
# This sets the *initial* state so a first login is themed. Afterwards
# theme-mode's push_hyprland() keeps GTK, the cursor and Kvantum following the
# desktop's light/dark setting, and it is the only thing that should write those
# keys at runtime. Both agree on the accent below.
set -euo pipefail

# Keep in sync with M.accent in home.tag-hyprland/.config/hypr/theme.lua and
# with `accent` in home/.local/bin/theme-mode. Three copies because three
# languages; the AUR list installs both flavours of exactly this accent.
readonly ACCENT=mauve

state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/theme-mode"
mode=$(cat "$state_dir/mode" 2>/dev/null || echo dark)
if [[ "$mode" == light ]]; then flavour=latte; else flavour=mocha; fi

# ── GTK ─────────────────────────────────────────────────────────────────────
# gsettings, not ~/.config/gtk-3.0/settings.ini: under Hyprland the settings
# portal is xdg-desktop-portal-gtk, which answers out of gsettings, so this is
# both the theme *and* the thing the portal publishes to everything else.
#
# Writing these while Plasma is the running session is harmless — kde-gtk-config
# owns GTK there and rewrites its own copies on login.
if command -v gsettings >/dev/null 2>&1; then
  gtk_if=org.gnome.desktop.interface
  gsettings set $gtk_if gtk-theme     "catppuccin-$flavour-$ACCENT-standard+default"
  gsettings set $gtk_if cursor-theme  "catppuccin-$flavour-$ACCENT-cursors"
  gsettings set $gtk_if cursor-size   24
  gsettings set $gtk_if icon-theme    "Papirus-$( [[ $mode == dark ]] && echo Dark || echo Light )"
  gsettings set $gtk_if font-name     "Noto Sans 10"
  gsettings set $gtk_if monospace-font-name "JetBrainsMono Nerd Font 10"

  # Only set color-scheme if it has never been set. It's the *source* of truth
  # under Hyprland — theme-toggle writes it and theme-mode reads it back — so
  # forcing it on every apply would silently undo a manual flip on the next
  # `hm apply`.
  if [[ "$(gsettings get $gtk_if color-scheme 2>/dev/null)" == "'default'" ]]; then
    gsettings set $gtk_if color-scheme "prefer-$( [[ $mode == dark ]] && echo dark || echo light )"
  fi
fi

# XCursor's own lookup path, which XWayland clients and a few GTK dialogs use
# instead of gsettings. Without it those windows fall back to the chunky black
# Adwaita cursor and you get two different pointers depending on which window
# you're over.
mkdir -p "$HOME/.icons/default"
printf '[Icon Theme]\nName=Default\nInherits=catppuccin-%s-%s-cursors\n' \
  "$flavour" "$ACCENT" > "$HOME/.icons/default/index.theme"

# ── Qt ──────────────────────────────────────────────────────────────────────
# env.lua sets QT_QPA_PLATFORMTHEME=qt6ct; this is the config it then reads.
# Kvantum does the actual drawing — qt6ct just selects it and supplies fonts.
#
# Only the style line is fixed here. Which Kvantum theme is active lives in
# kvantum.kvconfig, which theme-mode rewrites on every flip.
mkdir -p "$HOME/.config/qt6ct" "$HOME/.config/Kvantum"

cat > "$HOME/.config/qt6ct/qt6ct.conf" <<EOF
[Appearance]
style=kvantum
icon_theme=Papirus-$( [[ $mode == dark ]] && echo Dark || echo Light )
standard_dialogs=default

[Fonts]
fixed="JetBrainsMono Nerd Font,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="Noto Sans,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
cursor_flash_time=1000
dialog_buttons_have_icons=1
gui_effects=@Invalid()
menus_have_icons=true
show_shortcuts_in_context_menus=true
EOF

printf '[General]\ntheme=catppuccin-%s-%s\n' "$flavour" "$ACCENT" \
  > "$HOME/.config/Kvantum/kvantum.kvconfig"

# ── icons ───────────────────────────────────────────────────────────────────
# papirus-folders recolours Papirus's folder icons in place. It edits the
# system icon theme, so it needs root and only has to run when the colour
# actually differs from what's already applied.
if command -v papirus-folders >/dev/null 2>&1; then
  current=$(papirus-folders -l 2>/dev/null | awk '/current/ {print $NF}' || true)
  if [[ "$current" != "cat-$flavour-$ACCENT" ]]; then
    sudo papirus-folders -C "cat-$flavour-$ACCENT" --theme "Papirus-$( [[ $mode == dark ]] && echo Dark || echo Light )" >/dev/null 2>&1 \
      || echo "  papirus-folders: could not apply cat-$flavour-$ACCENT (non-fatal)" >&2
  fi
fi

echo "GTK/Qt/cursor themed for $flavour ($ACCENT)"
