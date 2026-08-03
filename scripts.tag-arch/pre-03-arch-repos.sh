#!/usr/bin/env bash
# Arch setup that has to land before the [packages] phase: the multilib repo
# (steam lives there), the build prerequisites and AUR helper that
# 00-aur-packages.sh needs, the 1Password release key those builds verify
# against, and the Flathub remote. Each step short-circuits when its target
# is already in place so re-runs don't need sudo.
set -euo pipefail

has_tag() { case ",$HM_TAGS," in *,"$1",*) return 0 ;; *) return 1 ;; esac; }

# steam is in multilib, which a stock install ships commented out. Append the
# stanza rather than uncommenting the one in place: the check and the edit
# then agree on exactly one pattern, and EOF is after core/extra, which is
# the ordering pacman wants anyway.
if ! grep -qE '^\[multilib\]' /etc/pacman.conf; then
  printf '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n' \
    | sudo tee -a /etc/pacman.conf >/dev/null

  # A newly enabled repo has no sync database yet, and the packages phase
  # deliberately never refreshes one — homie treats `pacman -Sy` followed by
  # an install as the partial-upgrade footgun it is. A full -Syu is the only
  # safe refresh, so it runs here, once, on the apply that flips multilib on.
  # Not on every apply: `hm apply` shouldn't hold the power to upgrade a
  # rolling system unattended.
  sudo pacman -Syu --noconfirm
fi

# makepkg needs a toolchain and paru's PKGBUILD needs git. [packages]
# declares base-devel too — that's where it belongs as a lasting part of the
# system — but the AUR helper has to exist before that phase runs.
#
# `pacman -Qq` first rather than leaning on `-S --needed` to no-op: --needed
# still goes through pacman, which still needs sudo, which on a converged host
# means a password prompt on every apply for no work.
if ! pacman -Qq base-devel git >/dev/null 2>&1; then
  sudo pacman -S --needed --noconfirm base-devel git
fi

# Tested by running it, not by `command -v paru`: paru links against libalpm,
# and the prebuilt paru-bin pins whichever soname it was built against while
# declaring only `libalpm.so>=14` — so on a host where pacman has moved on
# (paru-bin 2.1.0-1 wants libalpm.so.15; pacman 7.1 ships .16) it installs
# cleanly and then won't start. Building from source links against this host's
# pacman, and probing the binary instead of its presence means the next soname
# bump self-heals on the following apply rather than wedging every AUR install.
if ! paru --version >/dev/null 2>&1; then
  tmp=$(mktemp -d)
  trap 'rm -rf "$tmp"' EXIT
  git clone --depth=1 https://aur.archlinux.org/paru.git "$tmp/paru"
  # makepkg refuses to run as root by design; -s sudoes to install the cargo
  # makedepend, -i installs the built package, and -r drops that makedepend
  # again so the distro rust toolchain doesn't sit behind the rustup one
  # 01-rust-toolchain.sh manages.
  (cd "$tmp/paru" && makepkg -sir --noconfirm)
fi

# The 1password and 1password-cli PKGBUILDs verify their downloads against
# 1Password's release key, and makepkg looks for it in the *building user's*
# keyring — so this is a prerequisite for those builds, not a nicety. Same key
# the Fedora side imports into rpm, fetched from 1Password rather than a
# keyserver so there's one less service to be down.
op_key=3FEF9748469ADBE15DA7CA80AC2D62742012EA22
if ! gpg --list-keys "$op_key" >/dev/null 2>&1; then
  curl -fsSL https://downloads.1password.com/linux/keys/1password.asc \
    | gpg --quiet --import
fi

if has_tag desktop; then
  # Fedora's KDE spin ships flatpak; a base Arch install doesn't, and the
  # remote has to exist before the flatpak backend runs in the packages
  # phase. [packages] declares it as well, for the same reason base-devel is
  # declared there.
  if ! pacman -Qq flatpak >/dev/null 2>&1; then
    sudo pacman -S --needed --noconfirm flatpak
  fi

  # No filter dance needed here — unlike Fedora, Arch ships no FOSS-only
  # Flathub remote to widen, so adding it is the whole job.
  if ! flatpak remotes --system | awk '{print $1}' | grep -qFx flathub; then
    sudo flatpak remote-add --if-not-exists flathub \
      https://dl.flathub.org/repo/flathub.flatpakrepo
  fi
fi
