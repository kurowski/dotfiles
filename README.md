# dotfiles

Personal machine setup for Fedora (and devcontainers).

## Layout

- `setup.sh` — single entry point. Installs system packages on Fedora, symlinks dotfiles, sets up user-space tools.
- `hosts/<hostname>.env` — per-machine config (profile, theme, git identity, op account). New machine = new env file.
- `.zshrc`, `.gitconfig`, `.config/...` — real dotfiles, mirroring `$HOME` structure. Symlinked into place by `setup.sh`.

## Usage

```
./setup.sh
```

In a devcontainer / Codespace, system-level installs are skipped automatically.
