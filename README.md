# dotfiles

Ansible playbook for setting up Ubuntu machines. Supports work and personal profiles with per-machine customization.

## Prerequisites

```
sudo apt install ansible-core
```

## First-time 1Password setup

The playbook uses the 1Password CLI to inject secrets (atuin sync credentials, etc.). On a desktop machine, authenticate via the 1Password app's CLI integration. On a server:

```bash
# One-time: register your account (prompts for secret key and master password)
op account add --address my.1password.com --email brandt@kurowski.net

# Each session: authenticate before running the playbook
eval $(op signin --account my)
```

Sessions expire, so you'll need to re-run the `eval` line on subsequent runs. The playbook skips secret-dependent tasks gracefully if you're not signed in.

## Usage

```
ansible-playbook playbook.yml --limit $(hostname) -K
```
