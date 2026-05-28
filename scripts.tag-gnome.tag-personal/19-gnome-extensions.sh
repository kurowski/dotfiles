#!/usr/bin/env bash
# Install GNOME shell extensions not packaged for apt. Currently just
# display-brightness-ddcutil on personal GNOME desktops (uses ddcutil
# for external monitor brightness via DDC/CI).
set -euo pipefail

command -v gnome-extensions >/dev/null 2>&1 || exit 0
command -v gnome-shell      >/dev/null 2>&1 || exit 0

UUID="display-brightness-ddcutil@themightydeity.github.com"

if gnome-extensions info "$UUID" >/dev/null 2>&1; then
  exit 0
fi

shell_ver=$(gnome-shell --version | grep -oE '[0-9]+' | head -1)
api="https://extensions.gnome.org/extension-info/?uuid=${UUID}&shell_version=${shell_ver}"
dl_path=$(curl -fsS "$api" | python3 -c 'import sys,json; print(json.load(sys.stdin)["download_url"])')
zip=$(mktemp --suffix=.zip)
trap 'rm -f "$zip"' EXIT

curl -fsSL "https://extensions.gnome.org${dl_path}" -o "$zip"
gnome-extensions install --force "$zip"

# gnome-extensions enable refuses before the shell has reloaded the
# extension. Toggle the dconf list directly so it sticks across logins.
current=$(dconf read /org/gnome/shell/enabled-extensions 2>/dev/null || echo "[]")
if [[ -z "$current" || "$current" == "[]" ]]; then
  dconf write /org/gnome/shell/enabled-extensions "['$UUID']"
elif ! grep -q "$UUID" <<<"$current"; then
  updated=${current%]}", '$UUID']"
  dconf write /org/gnome/shell/enabled-extensions "$updated"
fi
