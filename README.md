# dotfiles

Ansible playbook for setting up Ubuntu machines. Supports work and personal profiles with per-machine customization.

## Prerequisites

```
sudo apt install ansible-core
```

## Usage

```
ansible-playbook playbook.yml --limit $(hostname) -K
```
