#!/usr/bin/env bash
# Wire libpam-fprintd into PAM stacks (sudo/login/etc.) so the
# fingerprint reader can authenticate. Idempotent — pam-auth-update
# is a no-op once the profile is already enabled.
set -euo pipefail

case ",$HM_TAGS," in *,ubuntu,*|*,debian,*) ;; *) exit 0 ;; esac
case ",$HM_TAGS," in *,desktop,*) ;; *) exit 0 ;; esac
command -v pam-auth-update >/dev/null 2>&1 || exit 0
[[ -f /usr/lib/x86_64-linux-gnu/security/pam_fprintd.so ]] || exit 0

# libpam-fprintd ships on Ubuntu desktop regardless of hardware, so the
# .so check above isn't enough. fprintd-list exits non-zero ("No devices
# available") when no fingerprint reader is present.
command -v fprintd-list >/dev/null 2>&1 || exit 0
fprintd-list "$USER" >/dev/null 2>&1 || exit 0

sudo pam-auth-update --enable fprintd
