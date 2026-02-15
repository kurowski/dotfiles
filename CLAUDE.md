# Dotfiles

Ansible-based dotfiles repo for automating Linux desktop setup across work and personal machines.

- **Public repo** — never commit secrets. Use 1Password CLI (`op://` URIs) for secret injection at runtime.
- Plans and design decisions live in `docs/plans/` as numbered files (001-skeleton.md, etc.) — read these for project history and context.
- All playbook runs are local (`ansible_connection=local`), never remote SSH.
- Work vs personal is distinguished via Ansible inventory groups and group_vars.
- `install.sh` is a lightweight non-Ansible script for devcontainer dotfiles setup.
