# Ansible Dotfiles Skeleton

## Context

Brandt is moving from chezmoi on Aurora Linux to a fresh Ansible-based dotfiles setup for Ubuntu. The repo needs to serve both work and personal machines, with per-machine customization via Ansible inventory. It also needs a lightweight (non-Ansible) install script for devcontainers that just sets up shell/editor config.

This first step is just the **skeleton** — repo structure, inventory, group/host vars, a minimal playbook that runs, and the devcontainer install script. No roles or real configuration yet; we'll add those incrementally in follow-up sessions.

**This repo will be public.** No secrets in any file. Secrets (API tokens, passwords, etc.) will be injected at runtime via 1Password CLI (`op read`, `op run`, etc.), matching the pattern already used in the existing chezmoi dotfiles.

## Machines

| Hostname     | Group    | Description              |
|-------------|----------|--------------------------|
| coach       | personal | Personal desktop (current) |
| cece        | personal | Personal laptop          |
| winston     | personal | Home server              |
| nick        | personal | Remote server            |
| uceap-dev01 | work     | Work Linux laptop        |

## Repo Structure

```
~/Projects/dotfiles/
├── ansible.cfg              # Local ansible config (inventory path, defaults)
├── playbook.yml             # Main playbook
├── inventory/
│   ├── hosts.yml            # All machines grouped by work/personal
│   ├── group_vars/
│   │   ├── all.yml          # Shared defaults (shell, editor, CLI tools)
│   │   ├── personal.yml     # Personal overrides (dark mode, personal email, etc.)
│   │   └── work.yml         # Work overrides (light mode, work email, etc.)
│   └── host_vars/
│       ├── coach.yml        # Desktop-specific (GNOME desktop apps, etc.)
│       ├── cece.yml         # Laptop-specific
│       ├── winston.yml      # Home server (no desktop)
│       ├── nick.yml         # Remote server (no desktop)
│       └── uceap-dev01.yml  # Work laptop-specific
├── roles/                   # Empty for now, we'll add roles incrementally
├── files/                   # Static config files (starship.toml, etc.) — added later
├── templates/               # Jinja2 templates (.zshrc.j2, .gitconfig.j2, etc.) — added later
├── docs/
│   └── plans/
│       └── 001-skeleton.md  # This plan (and future plans as 002-*, 003-*, etc.)
└── install.sh               # Lightweight devcontainer/dotfiles install script
```

## Files to Create

### `CLAUDE.md`
- This is an Ansible-based dotfiles repo for automating Linux desktop setup across work and personal machines
- The repo is **public** — never commit secrets; use 1Password CLI (`op://` URIs) for secret injection at runtime
- Plans and design decisions live in `docs/plans/` as numbered files (001-skeleton.md, etc.) — read these for project history and context
- All playbook runs are local (`ansible_connection=local`), never remote SSH
- Work vs personal is distinguished via Ansible inventory groups and group_vars
- `install.sh` is a lightweight non-Ansible script for devcontainer dotfiles setup



### `ansible.cfg`
- Set `inventory = inventory/hosts.yml`
- Set `localhost` connection defaults

### `inventory/hosts.yml`
- Two groups: `work` and `personal`
- All hosts use `ansible_connection=local` (playbook runs locally on each machine)
- Each host identified by hostname

### `inventory/group_vars/all.yml`
- Placeholder shared vars: `username`, `shell` (zsh), `editor` (nvim)
- No secrets — any secret references will use 1Password URI format (e.g., `op://vault/item/field`) to be resolved at runtime

### `inventory/group_vars/personal.yml`
- `git_email: brandt@kurowski.net`
- `theme: dark`
- `is_desktop: true` (overridden per host)

### `inventory/group_vars/work.yml`
- `git_email: bkurowski@uceap.universityofcalifornia.edu`
- `theme: light`
- `is_desktop: true`

### `inventory/host_vars/*.yml`
- Minimal placeholders for now
- `winston.yml` and `nick.yml` set `is_desktop: false` (servers, no GUI)

### `playbook.yml`
- Targets the current hostname via `hosts: {{ ansible_hostname }}`
- A single debug task that prints the resolved vars to verify everything works

### `install.sh`
- Lightweight script for devcontainers (no Ansible dependency)
- Symlinks/copies shell config files (zshrc, starship.toml, gitconfig)
- Compatible with VS Code devcontainer dotfiles support
- Detects if running in a container and skips desktop-only config

## Verification

After creating the skeleton:
1. Run `ansible-playbook playbook.yml --limit coach` — should print resolved vars for this machine
2. Run `ansible-playbook playbook.yml --limit uceap-dev01` — should show work vars (will only work on that machine, but we can use `--check` to validate)
3. Confirm `install.sh` is executable
