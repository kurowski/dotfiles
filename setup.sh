#!/usr/bin/env bash
# Dotfiles + machine setup for Fedora (and devcontainers).
# Run: ./setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
HOST="$(hostname)"

# --- Context detection -------------------------------------------------------

# Devcontainer / Codespaces / generic Docker. When set, skip system-level
# (sudo dnf) work; only do user-space dotfiles and a minimal tool set.
if [[ -f /.dockerenv ]] || [[ -n "${REMOTE_CONTAINERS:-}" ]] || [[ -n "${CODESPACES:-}" ]]; then
  IS_CONTAINER=1
else
  IS_CONTAINER=0
fi

# --- Load host vars ----------------------------------------------------------

HOST_ENV="$REPO_DIR/hosts/$HOST.env"
if [[ -f "$HOST_ENV" ]]; then
  # shellcheck disable=SC1090
  source "$HOST_ENV"
elif [[ "$IS_CONTAINER" == 1 ]]; then
  # Containers don't have a hosts/<container-id>.env file — use safe defaults.
  PROFILE="${PROFILE:-devcontainer}"
  THEME="${THEME:-dark}"
  GIT_NAME="${GIT_NAME:-Brandt Kurowski}"
  GIT_EMAIL="${GIT_EMAIL:-brandt@kurowski.net}"
else
  echo "ERROR: no host config at $HOST_ENV — create it or pass HOST=<name>" >&2
  exit 1
fi

echo "==> host=$HOST profile=$PROFILE container=$IS_CONTAINER"

# --- Cache sudo upfront (so we don't trip pam_fprintd repeatedly) -----------

if [[ "$IS_CONTAINER" == 0 ]]; then
  echo "==> caching sudo credentials"
  sudo -v
  # Refresh sudo cred in the background until this script exits, so long
  # installs don't lapse it. Errors silenced — when the subshell can't see
  # the cached cred (timestamp isolation), the real foreground sudo calls
  # still get their own cache hit; this loop is best-effort insurance.
  ( while true; do sudo -nv >/dev/null 2>&1 || true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT
fi

# --- System packages (Fedora only) -------------------------------------------

install_packages() {
  echo "==> enabling third-party repos"

  # All three of these are idempotent: copr enable no-ops if already on,
  # rpm --import no-ops on duplicate keys, and tee just rewrites the same
  # content. So no wrapper guards needed.

  sudo dnf copr enable -y atim/lazygit
  sudo dnf copr enable -y scottames/ghostty
  sudo dnf copr enable -y varlad/zellij

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
  # ±1 minor skew policy with the cluster). Bump v1.34 here when moving to
  # a new minor.
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

  # Docker CE (per https://docs.docker.com/engine/install/fedora/)
  curl -fsSL https://download.docker.com/linux/fedora/docker-ce.repo \
    | sudo tee /etc/yum.repos.d/docker-ce.repo >/dev/null

  # podman-docker's /usr/bin/docker shim conflicts with docker-ce's binary
  sudo dnf remove -y podman-docker 2>/dev/null || true

  echo "==> installing packages"
  sudo dnf install -y \
    1password \
    1password-cli \
    atuin \
    code \
    curl \
    ddcutil \
    deskflow \
    fastfetch \
    fprintd \
    gcc \
    gh \
    ghostty \
    git \
    glow \
    google-chrome-stable \
    helm \
    kubectl \
    lazygit \
    make \
    neovim \
    nodejs \
    npm \
    openssh-server \
    python3-pip \
    rustup \
    terraform \
    zellij \
    zsh

  # Docker CE — separate install because docker-ce.repo was added above
  # after removing podman-docker.
  sudo dnf install -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

  sudo systemctl enable --now docker
  if ! id -nG "$USER" | grep -qw docker; then
    sudo usermod -aG docker "$USER"
    echo "  added $USER to docker group (takes effect on next login)"
  fi

  # AWS Session Manager plugin — AWS hosts a single `latest` URL (no yum
  # repo), so re-runs download the current rpm; dnf no-ops when already
  # at that version, upgrades when AWS publishes a new one.
  sudo dnf install -y https://s3.amazonaws.com/session-manager-downloads/plugin/latest/linux_64bit/session-manager-plugin.rpm
}

# Fedora's `rustup` package only ships `rustup-init`; the real `rustup`
# binary + toolchain land in ~/.cargo/bin after running rustup-init. We
# pass --no-modify-path because our .zshrc already adds ~/.cargo/bin.
install_rust_toolchain() {
  if [[ -x "$HOME/.cargo/bin/rustup" ]]; then
    return
  fi
  echo "==> installing rust stable toolchain"
  rustup-init -y --default-toolchain stable --no-modify-path
}

# --- System packages (Debian — devcontainers) --------------------------------

# Personal CLI tools only — no infra (terraform/kubectl) or GUI apps. Everything
# in this list ships in trixie's main repo as of 2026-05; if a future tool isn't
# packaged, prefer adding a dedicated installer (see install_zellij) over pulling
# in a third-party apt repo.
install_packages_debian() {
  echo "==> installing apt packages"
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update -qq
  sudo apt-get install -y --no-install-recommends \
    atuin \
    bat \
    fastfetch \
    fd-find \
    fzf \
    glow \
    lazygit \
    ripgrep \
    zsh
}

# Debian trixie ships neovim 0.10, but AstroNvim needs >= 0.11. Pull the
# upstream prebuilt and drop it under ~/.local/nvim, symlinked into
# ~/.local/bin (which is ahead of /usr/bin on PATH per .zshrc).
install_neovim() {
  local prefix="$HOME/.local/nvim"
  if [[ -x "$prefix/bin/nvim" ]]; then
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64)  arch="linux-x86_64" ;;
    aarch64) arch="linux-arm64" ;;
    *) echo "  unsupported arch for neovim: $(uname -m); skipping"; return ;;
  esac
  echo "==> installing neovim to $prefix"
  mkdir -p "$HOME/.local/bin"
  local tmp
  tmp="$(mktemp -d)"
  curl -sSfL "https://github.com/neovim/neovim/releases/latest/download/nvim-${arch}.tar.gz" \
    | tar xz -C "$tmp"
  rm -rf "$prefix"
  mv "$tmp/nvim-${arch}" "$prefix"
  rm -rf "$tmp"
  ln -snf "$prefix/bin/nvim" "$HOME/.local/bin/nvim"
}

# zellij isn't packaged in Debian. Grab the prebuilt musl binary from the
# upstream release and drop it in ~/.local/bin (already on PATH via .zshrc).
install_zellij() {
  if command -v zellij >/dev/null 2>&1; then
    return
  fi
  local arch
  case "$(uname -m)" in
    x86_64)  arch="x86_64-unknown-linux-musl" ;;
    aarch64) arch="aarch64-unknown-linux-musl" ;;
    *) echo "  unsupported arch for zellij: $(uname -m); skipping"; return ;;
  esac
  echo "==> installing zellij to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  local tmp
  tmp="$(mktemp -d)"
  curl -sSfL "https://github.com/zellij-org/zellij/releases/latest/download/zellij-${arch}.tar.gz" \
    | tar xz -C "$tmp"
  mv "$tmp/zellij" "$HOME/.local/bin/zellij"
  chmod +x "$HOME/.local/bin/zellij"
  rm -rf "$tmp"
}

# @devcontainers/cli has no standalone binary release; npm is the supported
# install path. Use --prefix to land in ~/.local (already on PATH) instead of
# writing to /usr with sudo.
install_devcontainer_cli() {
  if command -v devcontainer >/dev/null 2>&1; then
    return
  fi
  echo "==> installing @devcontainers/cli to ~/.local"
  mkdir -p "$HOME/.local"
  npm install -g --prefix "$HOME/.local" @devcontainers/cli
}

# --- User-space tools (works in containers too) ------------------------------

install_starship() {
  if command -v starship >/dev/null 2>&1; then
    return
  fi
  echo "==> installing starship to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" --yes
}

# JetBrainsMono Nerd Font (not in Fedora repos — Fedora has plain
# `jetbrains-mono-fonts` but not the Nerd-patched variant needed for
# starship/ghostty glyphs). Fetch from upstream release.
install_nerd_font() {
  local font_dir="$HOME/.local/share/fonts/JetBrainsMono"
  if [[ -d "$font_dir" ]] && compgen -G "$font_dir/*.ttf" >/dev/null; then
    return
  fi
  echo "==> installing JetBrainsMono Nerd Font"
  mkdir -p "$font_dir"
  curl -sSfL https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz \
    | tar xJ -C "$font_dir"
  fc-cache -f "$font_dir" >/dev/null
}

# --- Default shell -----------------------------------------------------------

set_default_shell() {
  local target=/usr/bin/zsh
  if [[ "$(getent passwd "$USER" | cut -d: -f7)" == "$target" ]]; then
    return
  fi
  echo "==> chsh to $target"
  sudo chsh -s "$target" "$USER"
}

# --- Flatpaks ----------------------------------------------------------------

# Fedora ships a filtered Flathub remote (FOSS-only). `--no-filter` switches
# the existing system remote to the full Flathub catalog so proprietary apps
# (Obsidian, Zoom) are visible. Both calls are idempotent.
install_flatpaks() {
  echo "==> installing flatpaks"
  sudo flatpak remote-add --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
  sudo flatpak remote-modify --system flathub --no-filter
  sudo flatpak install -y --noninteractive flathub \
    md.obsidian.Obsidian \
    us.zoom.Zoom

  # Plasma caches don't pick up freshly-installed flatpaks until the next
  # session start; refresh them here so icons + menu entries appear without
  # needing a logout. `|| true` because these are best-effort — missing
  # gtk-update-icon-cache or kbuildsycoca6 (e.g. on non-KDE Fedora) shouldn't
  # fail the run.
  sudo gtk-update-icon-cache -fq /var/lib/flatpak/exports/share/icons/hicolor 2>/dev/null || true
  kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
}

# --- AstroNvim ---------------------------------------------------------------

# Clone the AstroNvim starter template if ~/.config/nvim is empty. Our
# colorscheme override gets symlinked in by link_dotfiles afterwards, so
# this must run before that.
setup_astronvim() {
  if [[ -d "$HOME/.config/nvim/.git" ]]; then
    return
  fi
  if [[ -e "$HOME/.config/nvim" ]] && [[ -n "$(ls -A "$HOME/.config/nvim" 2>/dev/null)" ]]; then
    echo "  ~/.config/nvim exists but isn't an AstroNvim clone; skipping"
    return
  fi
  echo "==> cloning AstroNvim template"
  git clone https://github.com/AstroNvim/template "$HOME/.config/nvim"
}

# --- Atuin sync --------------------------------------------------------------

# Log in to atuin's sync server using credentials stored in 1Password.
# Requires the 1Password app's CLI integration to be enabled so `op read`
# can unlock without an interactive sign-in.
setup_atuin_sync() {
  if [[ "${ATUIN_SYNC:-}" != "true" ]]; then
    return
  fi
  # `atuin status` exits non-zero with "not logged in to a sync server"
  # when no sync account is configured. A clean exit means we're good.
  if atuin status >/dev/null 2>&1; then
    return
  fi
  if ! command -v op >/dev/null 2>&1 || ! op vault list --account "$OP_ACCOUNT" >/dev/null 2>&1; then
    echo "  atuin sync requested but op CLI is not signed in to $OP_ACCOUNT; skipping"
    return
  fi
  echo "==> logging in to atuin sync"
  atuin login \
    -u "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin/username")" \
    -p "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin/password")" \
    -k "$(op read --account "$OP_ACCOUNT" "op://$ATUIN_VAULT/atuin-key/password")"
}

# --- Docker GHCR login -------------------------------------------------------

# Log Docker into GitHub Container Registry using gh's existing auth token.
# Needed to pull private org images (e.g., ghcr.io/uceap/*).
setup_docker_ghcr() {
  if ! command -v gh >/dev/null 2>&1 || ! command -v docker >/dev/null 2>&1; then
    return
  fi
  if docker system info >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "==> logging docker into ghcr.io"
    gh auth token | docker login ghcr.io -u "$(gh api user --jq .login 2>/dev/null || echo oauth2)" --password-stdin
  fi
}

# --- KDE config --------------------------------------------------------------

# Persistent KDE Plasma settings. kxkbrc is read at KDE session start, so
# the change takes effect on next login (or logout/login of the current
# session). kwriteconfig6 is idempotent — writing the same value is a no-op.
setup_kde() {
  kwriteconfig6 --file kxkbrc --group Layout --key Options "caps:escape"
}

# --- Gitconfig shim ----------------------------------------------------------

# Don't symlink ~/.gitconfig directly into the dotfiles repo: tools like the
# VS Code devcontainer extension call `git config --global credential.helper
# ...` on startup, and writes follow the symlink, polluting the repo with
# session-scoped paths. Instead, write a small real file at ~/.gitconfig that
# `[include]`s the dotfiles copy. Third-party writes land in the shim and
# leave the repo clean.
setup_gitconfig_shim() {
  local target="$HOME/.gitconfig"
  local include="$REPO_DIR/.gitconfig"
  # Migrate an older symlinked layout in place.
  if [[ -L "$target" ]]; then
    rm "$target"
  fi
  if [[ -f "$target" ]]; then
    if git config --file "$target" --get-all include.path 2>/dev/null \
        | grep -qFx "$include"; then
      return
    fi
    echo "==> adding dotfiles include to existing $target"
    git config --file "$target" --add include.path "$include"
    return
  fi
  echo "==> writing gitconfig shim to $target"
  cat > "$target" <<EOF
[include]
	path = $include
EOF
}

# --- Link dotfiles -----------------------------------------------------------

# Walk the repo and symlink every file under a path starting with "." into
# the matching location in $HOME. Real files at the target get backed up.
link_dotfiles() {
  echo "==> linking dotfiles"
  local relpath src target
  while IFS= read -r -d '' file; do
    relpath="${file#./}"
    case "$relpath" in
      .git/*|.gitignore|.gitconfig) continue ;;
      .*) ;;
      *) continue ;;
    esac
    src="$REPO_DIR/$relpath"
    target="$HOME/$relpath"
    if [[ -L "$target" && "$(readlink "$target")" == "$src" ]]; then
      continue
    fi
    if [[ -e "$target" && ! -L "$target" ]]; then
      mv "$target" "$target.bak.$(date +%s)"
      echo "  backed up existing $relpath"
    fi
    mkdir -p "$(dirname "$target")"
    ln -snf "$src" "$target"
    echo "  linked $relpath"
  done < <(cd "$REPO_DIR" && find . -type f -not -path './.git/*' -print0)
}

# --- Run ---------------------------------------------------------------------

if [[ "$IS_CONTAINER" == 0 ]]; then
  install_packages
  install_rust_toolchain
  install_devcontainer_cli
  install_flatpaks
  install_nerd_font
else
  install_packages_debian
  install_neovim
  install_zellij
fi

set_default_shell
install_starship
setup_gitconfig_shim
setup_astronvim
setup_atuin_sync
if [[ "$IS_CONTAINER" == 0 ]]; then
  setup_docker_ghcr
  setup_kde
fi
link_dotfiles

echo "==> done"
