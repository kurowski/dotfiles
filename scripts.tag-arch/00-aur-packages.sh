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
fi

if has_tag hyprland; then
  # Both flavours of everything, installed together rather than picked by
  # THEME. cece is the "auto" host, so the flavour isn't known at apply time —
  # it's whatever the desktop is set to right now, and it changes on KDE's
  # sunrise/sunset schedule. The switching is runtime (theme-mode), so both
  # sets of assets have to already be on disk. This is the same reason
  # home/.config/fzf carries fzfrc-latte *and* fzfrc-mocha.
  #
  # Plasma themes itself from its own settings and needs none of this; it's
  # scoped to the hyprland tag because outside a Plasma session, GTK, Qt,
  # cursors and the greeter each have to be told separately.
  pkgs+=(
    catppuccin-cursors-latte
    catppuccin-cursors-mocha
    catppuccin-gtk-theme-latte
    catppuccin-gtk-theme-mocha
    kvantum-theme-catppuccin-git
    papirus-folders-catppuccin-git
    # The greeter runs before login, so it has no session to follow and no
    # THEME to read. Both are installed; 25-sddm.sh picks one.
    catppuccin-sddm-theme-latte
    catppuccin-sddm-theme-mocha
    # Session exit menu, bound to a key under Hyprland — there's no Plasma
    # application launcher to hang logout/reboot/suspend off of.
    wlogout
    # Convertible bits: iio-hyprland reads iio-sensor-proxy and calls hyprctl
    # to rotate the display, wvkbd is the on-screen keyboard for tablet mode.
    # Neither has a counterpart under Plasma, which handles both natively.
    iio-hyprland-git
    wvkbd
  )
fi

paru -S --needed --noconfirm "${pkgs[@]}"
