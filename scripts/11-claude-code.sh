#!/usr/bin/env bash
# Claude Code CLI — no distro package; install via upstream installer.
# Install-once on purpose, unlike the other upstream-binary scripts: it
# keeps itself current (`claude update`, and auto-update by default), so
# a version check here would only ever race with it.
set -euo pipefail

command -v claude >/dev/null 2>&1 && exit 0

curl -fsSL https://claude.ai/install.sh | bash
