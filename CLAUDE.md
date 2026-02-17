# Dotfiles

Ansible-based dotfiles repo for automating Linux desktop setup across work and personal machines.

## Key rules

- **Public repo** — never commit secrets. Use 1Password CLI (`op://` URIs) for secret injection at runtime. Always specify `--account` (`my` for personal, `team-uceap` for work).
- All playbook runs are local (`ansible_connection=local`), never remote SSH. Run with `ansible-playbook playbook.yml --limit <hostname> -K`.
- `sudo-rs` is incompatible with Ansible — `become_exe = sudo.ws` in ansible.cfg. Don't change this.
- Avoid snap for CLI tools used in Ansible tasks (confinement issues). Snaps are fine for GUI apps.

## Structure

- `inventory/group_vars/` — work vs personal defaults (theme, email, 1Password account, snaps, dock favorites)
- `inventory/host_vars/` — per-machine overrides (servers: `is_desktop: false`, work: env template for op inject)
- `roles/` — each role handles one concern (packages, shell, gnome, etc.)
- `docs/plans/` — numbered plan files with project history and design decisions
- `install.sh` — lightweight non-Ansible script for devcontainer dotfiles (starship + atuin only)

## Adding new features

- New software/config → create a role in `roles/<name>/tasks/main.yml` and add it to `playbook.yml`
- Desktop-only roles → use `role: <name>` with `when: is_desktop | bool` in playbook.yml
- Per-group differences (dark/light, work/personal) → use `theme`, `op_account`, or other group vars in templates
- Secrets → use `op inject` for env vars (fast, single call) or `op read` for one-off tasks. Guard with `op account list` check for first-run bootstrap.
