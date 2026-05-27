# dotfiles

Personal Fedora setup, managed by [Homie](https://homie.sh).

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

- `homie.toml` — base config: Fedora package set, defaults, vars.
- `hosts/<hostname>.toml` — per-host overlay (deep-merged onto the base on each apply).
- `home/` — always-applied dotfiles. Plain files become symlinks; `*.tmpl` files render through Go templates.
- `home.tag-work/` — files that only apply on hosts tagged `work`.
- `scripts/pre-*.sh` — third-party repo setup, runs before `[packages]` install.
- `scripts/*.sh` — post-install setup (rust toolchain, AstroNvim clone, font install, etc.). Each script self-guards on `$HM_TAGS` and is idempotent.

## Hosts

- `coach` — personal Fedora workstation. Inherits the base `personal` profile.
- `uceap-dev01` — work Fedora laptop. Overrides profile to `work`, adds work-only packages (kubectl/helm/terraform/Chrome).

## Secrets

Secrets are *not* rendered by Homie. They flow from 1Password at runtime:

- KDE login fires `~/.local/bin/op-env-session`, which `op inject`s `~/.config/zshrc-env.op-tmpl` and pushes the resulting env vars to the systemd user environment. Subsequent zsh sessions inherit them.
- SSH / non-KDE sessions fall back to `op inject` on shell startup (see `~/.zshrc.local`).
- All of this is work-only — the `home.tag-work/` tree gates it on the `work` tag.
