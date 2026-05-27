#!/usr/bin/env bash
# AWS Session Manager plugin. AWS hosts a single `latest` URL with no
# yum repo, so re-runs download the current rpm; dnf no-ops when at
# that version, upgrades when AWS publishes a new one.
set -euo pipefail

case ",$HM_TAGS," in *,work,*) ;; *) exit 0 ;; esac
case ",$HM_TAGS," in *,fedora,*) ;; *) exit 0 ;; esac

sudo dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
