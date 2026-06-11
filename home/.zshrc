# Devcontainer shells often start without a login session, so $USER is
# unset even though `id -un` knows the name. Normalize it before anything
# else runs.
: ${USER:=$(id -un)}
export USER

export EDITOR=nvim
export VISUAL=$EDITOR
export LANG=en_US.UTF-8
export GOPATH="$HOME/go"

# Catppuccin colors for fzf (rendered per-host by homie; see ~/.config/fzf/fzfrc).
[[ -f "$HOME/.config/fzf/fzfrc" ]] && export FZF_DEFAULT_OPTS_FILE="$HOME/.config/fzf/fzfrc"

# rg skips dotfiles by default; the config turns on --hidden (minus .git).
# rg silently ignores a missing config file, so no existence guard needed.
export RIPGREP_CONFIG_PATH="$HOME/.config/ripgrep/config"

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

# ── Completions ────────────────────────────────────────────────────────────
# Cached completions generated at apply time (scripts/18-zsh-completions.sh)
# for tools with a generator but no fpath file (gh, docker, op, cargo, rustup,
# tailscale, starship). Prepended so current versions win over zsh's bundled
# ones. Must be on fpath before compinit.
fpath=("$HOME/.zsh/completions" $fpath)

# Initialize the completion system, rebuilding the dump at most once a day so
# fresh shells (devcontainers!) start fast.
autoload -Uz compinit
() {
  local dump=${ZDOTDIR:-$HOME}/.zcompdump
  local -a fresh=( $dump(Nmh-24) )
  if (( $#fresh )); then compinit -C; else compinit; fi
}

# Completion UX: case-insensitive, colorized, grouped with headers. fzf-tab
# owns the actual menu (so disable zsh's built-in select menu).
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '[%d]'

# aws uses a bash-style dynamic completer (no static compdef file possible),
# so it's wired here rather than cached on fpath above.
if command -v aws_completer >/dev/null 2>&1; then
  autoload -Uz bashcompinit && bashcompinit
  complete -C aws_completer aws
fi

# ── Plugins ────────────────────────────────────────────────────────────────
# Cloned into ~/.zsh/plugins by homie's [externals] phase. Load order
# matters: fzf-tab after compinit but before widget-wrapping plugins;
# autosuggestions before the syntax highlighter (patina, activated at EOF).
zsh_plug() { [[ -f "$HOME/.zsh/plugins/$1/$2" ]] && source "$HOME/.zsh/plugins/$1/$2" }

zsh_plug fzf-tab fzf-tab.plugin.zsh
zstyle ':fzf-tab:*' use-fzf-default-opts yes   # inherit catppuccin FZF opts
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=auto $realpath'

zsh_plug zsh-autosuggestions zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# zoxide: frecency-based smart cd (`z foo`, `zi` for interactive).
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
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

# opencode
export PATH=/home/brandt/.opencode/bin:$PATH

# Syntax highlighting — MUST be last: patina wraps ZLE widgets and needs
# every other plugin (autosuggestions, completion) already registered.
if command -v zsh-patina >/dev/null 2>&1; then
  eval "$(zsh-patina activate)"
fi
