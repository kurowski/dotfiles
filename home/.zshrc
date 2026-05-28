# Devcontainer shells often start without a login session, so $USER is
# unset even though `id -un` knows the name. Normalize it before anything
# else runs.
: ${USER:=$(id -un)}
export USER

export EDITOR=nvim
export VISUAL=$EDITOR
export LANG=en_US.UTF-8
export GOPATH="$HOME/go"

path=("$HOME/.cargo/bin" "$HOME/.atuin/bin" "$HOME/.local/bin" "$HOME/.devcontainers/bin" "$GOPATH/bin" $path)

if [[ -S "$HOME/.1password/agent.sock" ]]; then
  export SSH_AUTH_SOCK="$HOME/.1password/agent.sock"
  export OP_BIOMETRIC_UNLOCK_ENABLED=true
fi

if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  export NVM_DIR="$HOME/.nvm"
  source "$NVM_DIR/nvm.sh"
fi

if command -v atuin >/dev/null 2>&1; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

alias vim=nvim

if command -v eza >/dev/null 2>&1; then
  alias ls='eza'
  alias ll='eza -l --git --icons=auto'
  alias la='eza -la --git --icons=auto'
fi

# Debian/Ubuntu rename these to dodge namespace clashes; restore the standard
# names so muscle memory works the same as on Fedora.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd=fdfind
fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat=batcat
fi

oc() {
  docker start obsidian-claude 2>/dev/null
  docker exec -it obsidian-claude claude "$@"
}
alias ocr='oc --resume'

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
