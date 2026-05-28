#!/usr/bin/env bash
# Third-party APT repos for Ubuntu: gh, 1Password (+ debsig policy),
# VS Code bootstrap (desktop), Tailscale (personal), Mozilla Firefox
# w/ snap-shim block (desktop), and the Flathub remote (desktop).
# Each step short-circuits when its target is already in place.
set -euo pipefail

has_tag() { case ",$HM_TAGS," in *,"$1",*) return 0 ;; *) return 1 ;; esac; }

sudo install -d -m 0755 /etc/apt/keyrings

# --- GitHub CLI ---
if [[ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]]; then
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod 0644 /etc/apt/keyrings/githubcli-archive-keyring.gpg
fi
if [[ ! -f /etc/apt/sources.list.d/github-cli.list ]]; then
  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
fi

# --- 1Password ---
if [[ ! -f /usr/share/keyrings/1password-archive-keyring.gpg ]]; then
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor -o /usr/share/keyrings/1password-archive-keyring.gpg
fi
if [[ ! -f /etc/apt/sources.list.d/1password.list ]]; then
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main" \
    | sudo tee /etc/apt/sources.list.d/1password.list >/dev/null
fi
# 1Password requires a debsig policy to verify package signatures.
if [[ ! -f /etc/debsig/policies/AC2D62742012EA22/1password.pol ]]; then
  sudo install -d -m 0755 /etc/debsig/policies/AC2D62742012EA22
  sudo curl -fsSL https://downloads.1password.com/linux/debian/debsig/1password.pol \
    -o /etc/debsig/policies/AC2D62742012EA22/1password.pol
fi
if [[ ! -d /usr/share/debsig/keyrings/AC2D62742012EA22 ]]; then
  sudo install -d -m 0755 /usr/share/debsig/keyrings/AC2D62742012EA22
  sudo curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg
fi

# --- Tailscale (personal hosts) ---
if has_tag personal; then
  release=$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
  if [[ ! -f /usr/share/keyrings/tailscale-archive-keyring.gpg ]]; then
    sudo curl -fsSL "https://pkgs.tailscale.com/stable/ubuntu/${release}.noarmor.gpg" \
      -o /usr/share/keyrings/tailscale-archive-keyring.gpg
  fi
  if [[ ! -f /etc/apt/sources.list.d/tailscale.list ]]; then
    echo "deb [signed-by=/usr/share/keyrings/tailscale-archive-keyring.gpg] https://pkgs.tailscale.com/stable/ubuntu ${release} main" \
      | sudo tee /etc/apt/sources.list.d/tailscale.list >/dev/null
  fi
  # Snap tailscale conflicts with the apt package; harmless if not present.
  if command -v snap >/dev/null 2>&1 && snap list tailscale >/dev/null 2>&1; then
    sudo snap remove tailscale || true
  fi
fi

# --- Desktop-only repos / removals ---
if has_tag desktop; then
  # VS Code: bootstrap an apt source only if the .deb hasn't yet
  # created its self-managed /etc/apt/sources.list.d/vscode.sources.
  # If it has, remove any stale manual source to avoid Signed-By conflicts.
  if [[ -f /etc/apt/sources.list.d/vscode.sources ]]; then
    sudo rm -f /etc/apt/sources.list.d/vscode.list /usr/share/keyrings/microsoft.gpg
  else
    if [[ ! -f /usr/share/keyrings/microsoft.gpg ]]; then
      curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
    fi
    if [[ ! -f /etc/apt/sources.list.d/vscode.list ]]; then
      echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
    fi
  fi

  # Mozilla Firefox repo + snap-shim block. Ubuntu's firefox deb is a
  # shim that redirects to snap; its epoch 1:1snap1-* sorts above
  # Mozilla's real version, so we pin the Ubuntu copy to -1 (never
  # install) and the Mozilla copy to 1000 (always win).
  if [[ ! -f /etc/apt/keyrings/packages.mozilla.org.asc ]]; then
    sudo curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg \
      -o /etc/apt/keyrings/packages.mozilla.org.asc
  fi
  if [[ ! -f /etc/apt/sources.list.d/mozilla.list ]]; then
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" \
      | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
  fi
  if [[ ! -f /etc/apt/preferences.d/mozilla ]]; then
    sudo tee /etc/apt/preferences.d/mozilla >/dev/null <<'EOF'
Package: firefox*
Pin: release o=packages.mozilla.org
Pin-Priority: 1000

Package: firefox*
Pin: release o=Ubuntu
Pin-Priority: -1
EOF
  fi

  # If the Ubuntu snap-shim deb is installed, remove it before the
  # Mozilla version goes in. dpkg-query exits 1 when not installed.
  if dpkg-query -W -f='${Version}' firefox 2>/dev/null | grep -q '^1:1snap1'; then
    sudo apt-get remove -y firefox
  fi

  if command -v snap >/dev/null 2>&1 && snap list firefox >/dev/null 2>&1; then
    sudo snap remove firefox || true
  fi

  # Install Firefox here (not via [packages].debian) so we can pass
  # --allow-downgrades — needed if the snap-shim deb's epoch version
  # is still in apt's view of the cache.
  ff_ver=$(dpkg-query -W -f='${Version}' firefox 2>/dev/null || true)
  if [[ -z "$ff_ver" || "$ff_ver" == 1:1snap1* ]]; then
    sudo apt-get update -qq
    sudo apt-get install -y --allow-downgrades firefox
  fi

  # wsdd causes an AppArmor audit storm on Ubuntu GNOME desktops.
  if dpkg-query -W -f='${Status}' wsdd 2>/dev/null | grep -q 'install ok installed'; then
    sudo apt-get remove -y wsdd
  fi

  # Flathub for Obsidian (and anything else we add). Add as system-wide.
  if command -v flatpak >/dev/null 2>&1; then
    if ! flatpak remotes --system | awk '{print $1}' | grep -qFx flathub; then
      sudo flatpak remote-add flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    fi
  fi
fi
