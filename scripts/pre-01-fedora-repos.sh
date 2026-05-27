#!/usr/bin/env bash
# Third-party repos for Fedora: COPRs, dnf repos (VS Code, 1Password,
# Docker CE), profile-specific (Chrome/k8s/HashiCorp on work, RPM Fusion
# on personal), and the Flathub remote. All steps are idempotent.
set -euo pipefail

case ",$HM_TAGS," in *,fedora,*) ;; *) exit 0 ;; esac

sudo dnf copr enable -y atim/lazygit
sudo dnf copr enable -y scottames/ghostty

sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo tee /etc/yum.repos.d/code.repo >/dev/null <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
sudo tee /etc/yum.repos.d/1password.repo >/dev/null <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF

if [[ ",$HM_TAGS," == *,work,* ]]; then
  sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
  sudo tee /etc/yum.repos.d/google-chrome.repo >/dev/null <<'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

  # Kubernetes' yum repo is pinned per minor by design (kubectl follows a
  # ±1 minor skew policy with the cluster). Bump v1.34 here when moving
  # to a new minor.
  sudo rpm --import https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
  sudo tee /etc/yum.repos.d/kubernetes.repo >/dev/null <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.34/rpm/repodata/repomd.xml.key
EOF

  # HashiCorp's Fedora repo lags one or two releases behind current Fedora.
  # As of 2026-05 they publish only fedora/42 and fedora/43; fedora/44+ 404s.
  # Pin to 43 until they catch up — packages are still RPMs that work on F44.
  sudo rpm --import https://rpm.releases.hashicorp.com/gpg
  sudo tee /etc/yum.repos.d/hashicorp.repo >/dev/null <<'EOF'
[hashicorp]
name=Hashicorp Stable - $basearch
baseurl=https://rpm.releases.hashicorp.com/fedora/43/$basearch/stable
enabled=1
gpgcheck=1
gpgkey=https://rpm.releases.hashicorp.com/gpg
EOF
fi

if [[ ",$HM_TAGS," == *,personal,* ]]; then
  # RPM Fusion free + nonfree — required for Steam (nonfree) and full
  # ffmpeg/codecs (free). The release RPMs drop the .repo file + GPG key.
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
fi

# Docker CE (per https://docs.docker.com/engine/install/fedora/)
curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo \
  | sudo tee /etc/yum.repos.d/docker-ce.repo >/dev/null

# podman-docker's /usr/bin/docker shim conflicts with docker-ce's binary
sudo dnf remove -y podman-docker 2>/dev/null || true

# Fedora ships a filtered Flathub remote (FOSS-only). Switch to the full
# Flathub catalog so proprietary apps (Obsidian, Zoom) are visible.
if command -v flatpak >/dev/null 2>&1; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak remote-modify --system flathub --no-filter
fi
