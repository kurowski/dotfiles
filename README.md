# dotfiles

Personal multi-host setup for Fedora, Arch, Ubuntu, and macOS, managed by [Homie](https://homie.sh).

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
- `scripts/lib/*.bash` — sourced helpers, not scripts (the `*.sh` glob skips them).

## Upstream binaries

Tools whose packaged versions lag (atuin, neovim, starship, tpack, the
devcontainer CLI) are installed straight from upstream releases into
`~/.local/bin`, which `.zshrc` puts ahead of `/usr/bin` — so they win over
any distro copy still lying around. Those scripts share
`scripts/lib/upstream.bash` and all follow one shape: resolve the newest
release, compare it to what's installed, no-op when they match. So `hm
apply` keeps them current instead of freezing each one at whatever version
its host was provisioned with.

Rust follows the same rule with its own machinery: rustup is bootstrapped
from upstream `rustup-init` (never a distro package, which builds it with
self-update disabled), and `rustup update` keeps both it and the toolchain
current. Deliberately different: Claude Code self-updates, and nvm pins its
Node version on purpose.

## Theming

Everything is Catppuccin — latte when light, mocha when dark. On a desktop host
the desktop decides and the CLI/TUI stack follows it live, so it doesn't matter
whether the flip came from a schedule (KDE's own sunrise/sunset) or from
toggling it by hand — both are the same signal. The `THEME`
var (`light` / `dark`) is the fallback for when there's no desktop to ask: the
servers, containers, an SSH session with no session bus of its own, and macOS.

Following works because KDE and GNOME both publish the setting over the XDG
desktop portal (`org.freedesktop.appearance color-scheme`), and emit a signal
when it changes. `~/.local/bin/theme-mode` resolves the setting into
`~/.local/state/theme-mode/`, and `theme-mode.service` — enabled on every Linux
desktop host by `scripts/23-theme-mode.sh` — watches the portal and re-resolves
on every change. macOS is the one desktop left out: it keeps its appearance off
the portal, so `UCEAP-M1022` stays pinned to `THEME`.

Under Hyprland the portal answer comes from somewhere else.
`xdg-desktop-portal-hyprland` implements ScreenCast and GlobalShortcuts but
*not* `org.freedesktop.impl.portal.Settings`, so
`home.tag-hyprland/.config/xdg-desktop-portal/hyprland-portals.conf` routes that
one interface to `xdg-desktop-portal-gtk`, which answers out of gsettings
`org.gnome.desktop.interface color-scheme`. That makes gsettings the light/dark
authority in a Hyprland session, exactly as kdeglobals is in a Plasma one —
`theme-mode` reads the portal either way and never learns the difference.
`~/.local/bin/theme-toggle` (SUPER+SHIFT+T) is the switch, standing in for the
one Plasma has in its settings.

Getting from there to a repainted terminal takes three different mechanisms,
because the tools don't agree on how to be told:

- **ghostty needs nothing.** It reads the same portal setting itself, given
  `theme = light:…,dark:…`. eza and zsh-patina only ever use the 8 ANSI colors,
  so they follow ghostty for free.
- **Anything that starts fresh reads the environment.** `.zshrc` re-exports
  `BAT_THEME`, `DELTA_FEATURES`, `FZF_DEFAULT_OPTS_FILE`, `LG_CONFIG_FILE` and
  `STARSHIP_CONFIG` on every prompt, so shells that were *already open* when the
  desktop flipped follow along too — not just new ones. It's a builtin read of
  a one-line state file, no fork, and the exports only fire when the value
  actually changed.
- **Long-running tmux and nvim get pushed to,** since neither rereads its
  environment. `theme-mode reload` re-sources `tmux.conf` (catppuccin only
  rebuilds the status bar on a fresh run) and sets `background` in every live
  nvim over `--remote-expr`, which `colorscheme.lua` turns into a repaint.

Two files are generated rather than symlinked, both into
`~/.local/state/theme-mode/`: starship's config, because starship has no
include mechanism and no env override for `palette` — so the one line gets
rewritten into a copy, and `~/.config/starship.toml` stays the editable
original — and a one-line tmux flavor file that `tmux.conf` sources.

Adding a tool means giving it a per-flavor file (`fzfrc-latte` /
`fzfrc-mocha`, `theme-latte.yml` / `theme-mocha.yml`) and an export in the
`__theme_sync` block, not a new `{{ if eq .Vars.THEME }}` branch. The
templates are down to the two that genuinely can't be switched at runtime:
ghostty's config and delta's gitconfig fallback.

## Packages

Packages are declared per distro and per backend, scoped by tag:

```toml
[packages]                                     # always-applied base
fedora = [...]                                 # only on fedora hosts
arch   = [...]                                 # only on arch hosts (pacman)
debian = [...]                                 # only on ubuntu/debian hosts
macos  = [...]                                 # only on macos hosts (brew)

[packages."tag:desktop"]                       # one tag
debian = [...]
macos  = ["ghostty/cask"]                      # `/cask` suffix marks a brew cask

[packages."tag:desktop".flatpak]               # backend-scoped
all = [...]

[packages."tag:personal.tag:ubuntu".snap]      # AND-tagged + backend
all = [...]
```

On macOS the native manager is brew; append `/cask` to a name to mark it as a cask (e.g. `"1password/cask"`). Other backends: `flatpak`, `snap`. If the backend tool is missing, the block is skipped with a warning.

On Arch, `arch = [...]` covers the official repos only — Homie's pacman
backend stops there on purpose, and it never refreshes the sync database
(`pacman -Sy` then install is the partial-upgrade footgun). The AUR is driven
from `scripts.tag-arch/00-aur-packages.sh` via paru instead, which is where
1Password, the Microsoft VS Code build, Claude Desktop and seadrive-gui come
from — the Arch counterpart to the third-party dnf repos on Fedora. Name
packages, never pacman *groups* (`plasma`, `xorg`): nothing records that you
asked for a group, so Homie can't tell a complete one from a missing one.

Arch is also the one distro where the desktop itself is declared here
(`[packages."tag:kde"]` → `plasma-meta`, `sddm`). Everywhere else the KDE spin
or the Ubuntu installer provides it. That makes `hm apply` enough to take a
base Arch install to a working Plasma session on the next boot.

## Tags

Auto-derived per host:
- Distro: `fedora`, `arch`, `ubuntu`, `debian`, or `macos`.
- Profile: `personal` or `work`, from `[profile].name`.
- Misc: CPU architecture (`amd64` / `arm64` — *not* the `arch` distro tag),
  short hostname, `root`, `container`.

Manual, set per-host via `[tags].extra`:
- `desktop` / `server` — workstation vs. headless.
- `kde`, `gnome`, `hyprland` — desktop environment. Not mutually exclusive:
  cece carries both `kde` and `hyprland` and picks a session at the greeter.

## Hosts

| host          | distro | profile  | extra tags             | `THEME` |
| ------------- | ------ | -------- | ---------------------- | ------- |
| `coach`       | fedora | personal | desktop, kde           | dark    |
| `uceap-dev01` | fedora | work     | desktop, kde           | light   |
| `UCEAP-M1022` | macos  | work     | desktop                | light   |
| `cece`        | arch   | personal | desktop, kde, hyprland | dark    |
| `nick`        | ubuntu | personal | server                 | dark    |
| `winston`     | ubuntu | personal | server                 | dark    |

`THEME` is only the fallback — the three Linux desktops follow their desktop's
light/dark setting at runtime instead. See [Theming](#theming).

## Secrets

Secrets are *not* rendered by Homie. They flow from 1Password at runtime:

- KDE login fires `~/.local/bin/op-env-session`, which `op inject`s `~/.config/zshrc-env.op-tmpl` and pushes the resulting env vars to the systemd user environment. Subsequent zsh sessions inherit them.
- SSH / non-KDE sessions fall back to `op inject` on shell startup (see `~/.zshrc.local`).
- All of this is work-only — the `home.tag-work/` tree gates it on the `work` tag.
