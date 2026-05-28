# dotfiles

Personal multi-host setup for Fedora and Ubuntu, managed by [Homie](https://homie.sh).

## Bootstrap a fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/kurowski/dotfiles/main/bootstrap.sh | bash
```

That downloads `hm`, clones this repo to `~/Projects/dotfiles`, and runs `hm apply`.

## Day-to-day

```sh
hm apply       # full reconcile (packages + dotfiles + scripts)
hm home        # just refresh dotfile symlinks + templates
hm doctor      # check for broken symlinks / drift
hm status      # read-only summary of what hm sees
```

## Layout

- `homie.toml` — base config: package sets per distro, defaults, vars.
- `hosts/<short-hostname>.toml` — per-host overlay, deep-merged onto the base.
- `home/` — always-applied dotfiles. Plain files become symlinks; `*.tmpl` files render through Go templates. `*.op-tmpl` files are *not* Homie templates — they're 1Password `op inject` sources that the runtime secret flow renders separately.
- `home.tag-X/` — files that only apply when tag `X` is active on the host. Multi-tag = AND (`home.tag-personal.tag-ubuntu/`).
- `scripts/pre-*.sh` — runs before `[packages]` install. Used for third-party repos.
- `scripts/*.sh` — post-install setup. Each script is idempotent.
- `scripts.tag-X/` — tag-gated scripts, same AND rule as `home.tag-X/`.

## Packages

Packages are declared per distro and per backend, scoped by tag:

```toml
[packages]                                     # always-applied base
fedora = [...]                                 # only on fedora hosts
debian = [...]                                 # only on ubuntu/debian hosts

[packages."tag:desktop"]                       # one tag
debian = [...]

[packages."tag:desktop".flatpak]               # backend-scoped
all = [...]

[packages."tag:personal.tag:ubuntu".snap]      # AND-tagged + backend
all = [...]
```

Backends: `flatpak`, `snap`, `brew`. If the backend tool is missing, the block is skipped with a warning.

## Tags

Auto-derived per host:
- Distro: `fedora`, `ubuntu`, or `debian`.
- Profile: `personal` or `work`, from `[profile].name`.
- Misc: arch, short hostname, `root`, `container`.

Manual, set per-host via `[tags].extra`:
- `desktop` / `server` — workstation vs. headless.
- `kde`, `gnome` — desktop environment.

## Hosts

| host          | distro | profile  | extra tags     |
| ------------- | ------ | -------- | -------------- |
| `coach`       | fedora | personal | desktop, kde   |
| `uceap-dev01` | fedora | work     | desktop, kde   |
| `cece`        | ubuntu | personal | desktop, gnome |
| `nick`        | ubuntu | personal | server         |
| `winston`     | ubuntu | personal | server         |

## Secrets

Secrets are *not* rendered by Homie. They flow from 1Password at runtime:

- KDE login fires `~/.local/bin/op-env-session`, which `op inject`s `~/.config/zshrc-env.op-tmpl` and pushes the resulting env vars to the systemd user environment. Subsequent zsh sessions inherit them.
- SSH / non-KDE sessions fall back to `op inject` on shell startup (see `~/.zshrc.local`).
- All of this is work-only — the `home.tag-work/` tree gates it on the `work` tag.
