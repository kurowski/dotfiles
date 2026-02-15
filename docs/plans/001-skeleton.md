# 001 — Skeleton & Shell Setup

## Status: Complete

## Context

Brandt is moving from chezmoi on Aurora Linux to a fresh Ansible-based dotfiles setup for Ubuntu. The repo needs to serve both work and personal machines, with per-machine customization via Ansible inventory. It also needs a lightweight (non-Ansible) install script for devcontainers that just sets up shell/editor config.

**This repo is public.** No secrets in any file. Secrets are injected at runtime via 1Password CLI (`op read --account <account> 'op://vault/item/field'`).

## What was built

### Skeleton
- Repo at `~/Projects/dotfiles/` with Ansible inventory for 5 machines
- Two groups: `work` (uceap-dev01) and `personal` (coach, cece, winston, nick)
- `group_vars/` for work vs personal defaults (theme, git email, is_desktop)
- `host_vars/` for per-machine overrides (servers set `is_desktop: false`)
- `install.sh` stub for devcontainer dotfiles (not yet wired up)
- `docs/plans/` for tracking design decisions

### 1Password role (`roles/onepassword`)
- Adds 1Password APT repo (GPG key, sources list, debsig policy)
- Installs `1password` and `1password-cli` packages
- Note: On first run, 1Password must be opened and CLI integration enabled manually before `op read` works

### Shell role (`roles/shell`)
- Installs zsh and sets it as default shell
- Installs starship prompt (via install script)
- Installs atuin (via install script, not snap — snap has confinement issues with Ansible)
- Logs in to atuin sync using 1Password credentials (skipped if `op` not yet authenticated)
- Deploys `.zshrc` with starship, atuin, zoxide init; devcontainer helpers; obsidian-claude functions
- Deploys `.zshrc.local` for per-machine env vars (work secrets via `op read`)
- Deploys `starship.toml` (Catppuccin Frappe theme, Nerd Font symbols, Aurora bits stripped)

## Lessons learned

- **sudo-rs incompatibility**: Ubuntu's sudo-rs doesn't work with Ansible's become mechanism. Workaround: `become_exe = sudo.ws` in ansible.cfg. Tracked at [ansible/ansible#85837](https://github.com/ansible/ansible/issues/85837).
- **Snap + Ansible**: Snap-installed tools (like atuin) have confinement issues when run from Ansible's shell tasks. Prefer native installs.
- **1Password circular dependency**: The playbook installs 1Password, but `op read` needs the app configured first. Solution: check `op account list` and skip tasks that need it when not yet authenticated. First run installs everything; second run (after signing into 1Password) completes setup.
- **Multiple 1Password accounts**: Must use `--account team-uceap` or `--account my` with `op read` to disambiguate.

## What's next

Potential future plans (not prioritized):
- GNOME/dconf settings (dark/light mode, caps→escape, fonts, extensions, tiling)
- Git config role (.gitconfig template with work/personal email)
- APT packages & custom repos (gh, tailscale, docker, ghostty, etc.)
- Snap/desktop app installation (Obsidian, Spotify, Firefox, etc.)
- Neovim/LazyVim config
- Fonts (Nerd Fonts installation)
- Wire up `install.sh` for devcontainer dotfiles
- VS Code settings sync strategy
