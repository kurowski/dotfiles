#!/usr/bin/env bash
# Wire libpam-fprintd into PAM stacks (sudo/login/etc.) so the
# fingerprint reader can authenticate. Idempotent — pam-auth-update
# is a no-op once the profile is already enabled.
set -euo pipefail

case ",$HM_TAGS," in *,ubuntu,*|*,debian,*) ;; *) exit 0 ;; esac
case ",$HM_TAGS," in *,desktop,*) ;; *) exit 0 ;; esac
command -v pam-auth-update >/dev/null 2>&1 || exit 0
[[ -f /usr/lib/x86_64-linux-gnu/security/pam_fprintd.so ]] || exit 0

sudo pam-auth-update --enable fprintd
