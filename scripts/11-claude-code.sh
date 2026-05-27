#!/usr/bin/env bash
# Claude Code CLI — no distro package; install via upstream installer.
set -euo pipefail

command -v claude >/dev/null 2>&1 && exit 0

curl -fsSL https://claude.ai/install.sh | bash
