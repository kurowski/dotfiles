#!/usr/bin/env bash
# AUR packages. Homie's pacman backend covers the official repos only — the
# AUR needs a helper that isn't part of a base install, so the handful of
# things that live only there are installed here instead of in [packages].
# paru comes from pre-03-arch-repos.sh.
#
# Numbered 00 so it lands before every other setup script: 06-atuin-sync.sh
# shells out to `op` and 18-zsh-completions.sh generates its completion, and
# both would silently skip on a first apply if the CLI arrived at the end.
#
# `-S --needed` is the same shape as the upstream-binary scripts: paru resolves
# each name against the AUR, no-ops when the installed version matches, and
# rebuilds when it doesn't — so these track upstream instead of freezing at
# whatever was current when the host was provisioned.
set -euo pipefail

command -v paru >/dev/null 2>&1 \
  || { echo "paru not found; skipping AUR packages" >&2; exit 0; }

has_tag() { case ",$HM_TAGS," in *,"$1",*) return 0 ;; *) return 1 ;; esac; }

pkgs=(
  # Fedora gets both of these from 1Password's own dnf repo.
  1password
  1password-cli
  # extra's `code` is the OSS build — no marketplace, no settings sync. This
  # is Microsoft's, matching the packages.microsoft.com build on Fedora.
  visual-studio-code-bin
)

if has_tag desktop; then
  # Anthropic's own .deb repackaged, so this is the official app — not the
  # community rebuild behind Fedora's claude-desktop-unofficial. It pulls
  # qemu + edk2-ovmf as real dependencies: Cowork runs its sandbox in a VM.
  pkgs+=(claude-desktop)
fi

if has_tag personal; then
  pkgs+=(seadrive-gui)

  # Music Assistant's desktop companion, the Arch half of
  # scripts.tag-personal/26-music-assistant.sh — same app, but here the AUR
  # is already watching upstream so there's no release-polling to do. The
  # -bin package takes the upstream deb rather than rebuilding the Tauri
  # app from source, matching the visual-studio-code-bin choice above.
  if has_tag desktop; then
    pkgs+=(music-assistant-desktop-bin)
  fi
fi

paru -S --needed --noconfirm "${pkgs[@]}"
