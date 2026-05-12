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

# Debian/Ubuntu rename these to dodge namespace clashes; restore the standard
# names so muscle memory works the same as on Fedora.
if ! command -v fd >/dev/null 2>&1 && command -v fdfind >/dev/null 2>&1; then
  alias fd=fdfind
fi
if ! command -v bat >/dev/null 2>&1 && command -v batcat >/dev/null 2>&1; then
  alias bat=batcat
fi

if command -v devcontainer >/dev/null 2>&1; then
  # All four accept an optional sub-config name (e.g. "portal") for repos
  # using the .devcontainer/<sub>/devcontainer.json layout. With no arg, the
  # CLI finds .devcontainer/devcontainer.json on its own.
  dcu() {
    local label="project=$(basename "$PWD")"
    local config_arg=()
    if [[ -n "$1" ]]; then
      config_arg=(--config ".devcontainer/$1/devcontainer.json")
      label="$label/$1"
    fi
    # --id-label is only applied as a real Docker label in the non-compose
    # path (CLI runs `docker run` itself); for compose configs it's a no-op
    # because the CLI delegates container creation to `docker compose`. It's
    # kept here so dck's non-compose branch can find the container by label.
    devcontainer up \
      --id-label="$label" \
      --workspace-folder . \
      "${config_arg[@]}" \
      --dotfiles-repository kurowski/dotfiles
  }
  dck() {
    local sub="$1"
    local dir=".devcontainer"
    [[ -n "$sub" ]] && dir=".devcontainer/$sub"
    local compose_file
    for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
      if [[ -f "$dir/$candidate" ]]; then
        compose_file="$dir/$candidate"
        break
      fi
    done
    if [[ -n "$compose_file" ]]; then
      # Compose path: dcu's --id-label was a no-op here, so identify the
      # containers by compose project name. Match the name the devcontainer
      # CLI uses: basename of the config dir, with any leading dot stripped
      # to match compose's sanitization.
      local project="$(basename "$dir")"
      project="${project#.}"
      docker compose --project-name "$project" -f "$compose_file" down
    else
      # Non-compose path: dcu applied --id-label as a real Docker label, so
      # filter on it to find the container.
      local label="project=$(basename "$PWD")"
      [[ -n "$sub" ]] && label="$label/$sub"
      docker ps --filter "label=$label" --format "{{.ID}}" | xargs -r docker rm -f
    fi
  }
  dce() {
    local sub="$1"
    local dir=".devcontainer"
    [[ -n "$sub" ]] && dir=".devcontainer/$sub"
    local config_arg=()
    [[ -n "$sub" ]] && config_arg=(--config "$dir/devcontainer.json")
    local session_name="${2:-devcontainer}"
    # In compose mode the CLI doesn't apply the devcontainer.local_folder /
    # devcontainer.config_file labels that exec normally filters on, so the
    # default lookup fails. Identify the dev-container ourselves (it's the
    # only service in the compose project that carries a devcontainer.metadata
    # label) and pass its id via --container-id.
    local container_id_arg=()
    local compose_file
    for candidate in docker-compose.yml docker-compose.yaml compose.yml compose.yaml; do
      if [[ -f "$dir/$candidate" ]]; then
        compose_file="$dir/$candidate"
        break
      fi
    done
    if [[ -n "$compose_file" ]]; then
      local project="$(basename "$dir")"
      project="${project#.}"
      # devcontainer.metadata alone isn't enough: other services in the
      # project (e.g. a Drupal reference container whose own image is built
      # from a devcontainer base) carry that label too. Disambiguate by the
      # compose service name declared in devcontainer.json. devcontainer.json
      # is JSONC so jq isn't reliable — grep the "service": line.
      local service=$(grep -oE '"service"[[:space:]]*:[[:space:]]*"[^"]+"' "$dir/devcontainer.json" 2>/dev/null \
        | head -1 | sed -E 's/.*"([^"]+)"$/\1/')
      if [[ -n "$service" ]]; then
        local container_id=$(docker ps \
          --filter "label=com.docker.compose.project=$project" \
          --filter "label=com.docker.compose.service=$service" \
          --format "{{.ID}}" | head -1)
        [[ -n "$container_id" ]] && container_id_arg=(--container-id "$container_id")
      fi
    fi
    devcontainer exec \
      --workspace-folder . \
      "${config_arg[@]}" \
      "${container_id_arg[@]}" \
      zellij attach "$session_name" --create
  }
  # Rebuild + reattach: VS Code's "Dev Container: Rebuild" equivalent.
  dcr() {
    dck "$1" && dcu "$1" && dce "$1" "$2"
  }
fi

oc() {
  docker start obsidian-claude 2>/dev/null
  docker exec -it obsidian-claude claude "$@"
}
alias ocr='oc --resume'

[[ -f "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
