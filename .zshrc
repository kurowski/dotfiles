export EDITOR=nvim
export VISUAL=$EDITOR

path=("$HOME/.cargo/bin" "$HOME/.atuin/bin" "$HOME/.local/bin" "$HOME/.devcontainers/bin" $path)

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

if command -v devcontainer >/dev/null 2>&1; then
  alias dcu='devcontainer up --id-label=project=$(basename $(pwd)) --workspace-folder . --dotfiles-repository kurowski/dotfiles'
  alias dck='docker ps --filter label=project=$(basename $(pwd)) --format "{{.ID}}" | xargs docker rm -f'
  dce() {
    local session_name="${1:-devcontainer}"
    devcontainer exec --id-label=project=$(basename $(pwd)) --workspace-folder . zellij attach "$session_name" --create
  }
fi

oc() {
  docker start obsidian-claude 2>/dev/null
  docker exec -it obsidian-claude claude "$@"
}
alias ocr='oc --resume'

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
