#!/usr/bin/env bash
# Enable sshd. Fedora's and Ubuntu's openssh-server packages turn the service
# on at install time via a systemd preset; Arch's `openssh` ships the unit
# disabled, so without this the hosts that declare it aren't reachable.
#
# The binary check doubles as the scope check — sshd only exists here because
# a tag block asked for openssh.
set -euo pipefail

[[ -x /usr/bin/sshd ]] || exit 0

if ! systemctl is-enabled sshd >/dev/null 2>&1; then
  sudo systemctl enable --now sshd
fi
