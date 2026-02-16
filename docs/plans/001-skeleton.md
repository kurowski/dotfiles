# 001 — Dotfiles Setup

## Status: Complete

## Context

Brandt is moving from chezmoi on Aurora Linux to a fresh Ansible-based dotfiles setup for Ubuntu. The repo serves both work and personal machines, with per-machine customization via Ansible inventory. A lightweight install script handles devcontainer dotfiles without Ansible.

**This repo is public.** No secrets in any file. Secrets are injected at runtime via 1Password CLI (`op inject` / `op read --account <account> 'op://vault/item/field'`).

## Machines

| Hostname     | Group    | Description              |
|-------------|----------|--------------------------|
| coach       | personal | Personal desktop         |
| cece        | personal | Personal laptop          |
| winston     | personal | Home server              |
| nick        | personal | Remote server            |
| uceap-dev01 | work     | Work Linux laptop        |

## Roles

| Role         | What it does                                                        |
|-------------|---------------------------------------------------------------------|
| packages     | Common APT packages (docker, gh, cargo, nodejs, lazygit, etc.), GitHub CLI repo, desktop packages (deskflow, ddcutil), docker group |
| onepassword  | 1Password APT repo, desktop app + CLI                              |
| lunarvim     | Neovim + LunarVim, config with gruvbox-baby (personal) / github-light (work) |
| shell        | Zsh, starship, atuin (with sync), devcontainer CLI, .zshrc, .zshrc.local (op inject), starship.toml |
| git          | .gitconfig template with per-group email, gh credential helper     |
| snaps        | Per-group snap packages (tailscale, VS Code, Obsidian, GIMP, Spotify) |
| tmux         | Tmux from apt, TPM, gruvbox dark (personal) / nord (work)         |
| ghostty      | Ghostty snap, config with Gruvbox Dark (personal) / Nord Light (work) |
| firefox      | Remove snap Firefox, install from Mozilla APT repo for 1Password native messaging |
| gnome        | Tweaks, fonts (JetBrainsMono Nerd Font), input (caps→escape, natural scroll), appearance (dark/light per group), terminal font/theme, window management, tiling assistant, dock, power, autostart, file manager |

## Devcontainer support

`install.sh` — lightweight script that VS Code runs when creating devcontainers:
- Installs starship and atuin if not present
- Symlinks starship.toml from the repo
- Appends starship + atuin init to existing .zshrc
- Git config inherited from host automatically

## Key patterns

- **Work vs personal**: Ansible inventory groups with `group_vars/` (theme, email, 1Password account, snap lists, dock favorites)
- **Per-host config**: `host_vars/` for machine-specific overrides (servers: `is_desktop: false`, work: env template for op inject)
- **Secrets**: Never in files. `op inject` for shell env vars (single fast call), `op read` for one-off tasks (atuin login). Always specify `--account`.
- **sudo-rs workaround**: `become_exe = sudo.ws` in ansible.cfg ([ansible#85837](https://github.com/ansible/ansible/issues/85837))
- **Snap avoidance for CLI tools**: Snap confinement breaks Ansible shell tasks. Use native installs for atuin, tmux. Snaps fine for GUI apps.
- **1Password bootstrap**: First run installs 1Password but can't use it yet. Tasks that need `op` check `op account list` and skip gracefully. Second run completes setup.

## What's next

Potential future enhancements:
- VS Code extensions list (currently using built-in Settings Sync)
- Tailscale configuration
- SSH server hardening
- Obsidian vault cloning per machine
- Deskflow configuration files
