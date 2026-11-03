# dotfiles

Personal multi-host setup for Fedora, Arch, Ubuntu, and macOS, managed by [Homie](https://homie.sh).

## Bootstrap a fresh machine

```sh
curl -fsSL https://raw.githubusercontent.com/kurowski/dotfiles/main/bootstrap.sh | bash
```

That downloads `homie`, clones this repo to `~/Projects/dotfiles`, and runs `homie apply`.

## Day-to-day

```sh
homie apply   # full reconcile (packages + dotfiles + scripts)
homie home    # just refresh dotfile symlinks + templates
homie doctor  # check for broken symlinks / drift
homie status  # read-only summary of what homie sees
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
devcontainer CLI), or that no distro here packages at all (superfile), are
installed straight from upstream releases into `~/.local/bin`, which `.zshrc`
puts ahead of `/usr/bin` — so they win over any distro copy still lying
around. Those scripts share `scripts/lib/upstream.bash` and all follow one
shape: resolve the newest release, compare it to what's installed, no-op when
they match. So `homie apply` keeps them current instead of freezing each one at
whatever version its host was provisioned with.

Rust follows the same rule with its own machinery: rustup is bootstrapped
from upstream `rustup-init` (never a distro package, which builds it with
self-update disabled), and `rustup update` keeps both it and the toolchain
current. Deliberately different: Claude Code self-updates, and nvm pins its
Node version on purpose.

The Music Assistant desktop companion follows the same resolve-compare-no-op
shape without being a `~/.local/bin` binary. It's in no distro repo and not on
Flathub, so `scripts.tag-personal/26-music-assistant.sh` installs the rpm (or
deb) straight from its GitHub release, which is what gets it a real `.desktop`
entry and icons. It does carry Tauri's self-updater, but that ships AppImage
payloads only on Linux — a native package install can't consume them, so the
script stands in for it. Arch is the exception: the AUR already tracks upstream,
so it's a name in `00-aur-packages.sh` instead.

`asdbctl` — brightness for the Apple Studio Display on `uceap-dev01`, which
answers no DDC/CI, so the `ddcutil` in the base list can't reach it — is the
third variation. Upstream ships no prebuilt binaries for any platform, so it's
`cargo install --git --tag` rather than a release download, and the version it
compares against comes from `cargo install --list` because the binary carries no
`--version` flag. Two things fall out of that. It's the one script that installs
a file outside `$HOME` (upstream's udev rule, so hidraw isn't root-only and the
tool works without sudo), written only when it differs so a re-apply doesn't
prompt. And it's the first `scripts.tag-<hostname>/` directory: the short
hostname is an auto-derived tag like any other, so gating on it needs no new
machinery — it's just narrower than `desktop`, which is the right scope for a
display sitting on exactly one desk. `systemd-devel`, the build dep its hidapi
crate needs, is scoped the same way, next to `fprintd` in that host's overlay.

## Theming

Everything is Catppuccin — latte when light, mocha when dark. On a desktop host
the desktop decides and the CLI/TUI stack follows it live, so it doesn't matter
whether the flip came from KDE's own sunrise/sunset schedule (cece) or from
toggling it by hand (everywhere else) — both are the same signal. The `THEME`
var (`light` / `dark`) is the fallback for when there's no desktop to ask: the
servers, containers, and an SSH session with no session bus of its own.

On Linux that works because KDE and GNOME both publish the setting over the XDG
desktop portal (`org.freedesktop.appearance color-scheme`), and emit a signal
when it changes. `~/.local/bin/theme-mode` resolves the setting into
`~/.local/state/theme-mode/`, and `theme-mode.service` — enabled on every Linux
desktop host by `scripts/23-theme-mode.sh` — watches the portal and re-resolves
on every change.

macOS answers the same question from `AppleInterfaceStyle`, which reads `Dark`
in dark mode and is absent entirely in light mode, and there's no bus to
monitor. The change does reach the filesystem though — toggling the appearance
rewrites `~/Library/Preferences/.GlobalPreferences.plist` a second or so later
— so `net.kurowski.theme-mode.plist` hands the watching to launchd's own
`WatchPaths` and runs `theme-mode reload` one-shot on each change. Nothing to
supervise, so there's no macOS counterpart to `theme-mode watch`. The lag is
whenever `cfprefsd` flushes: usually a second or two, up to about ten.

Getting from there to a repainted terminal takes three different mechanisms,
because the tools don't agree on how to be told:

- **ghostty needs nothing.** Given `theme = light:…,dark:…` it reads the system
  setting itself — the portal on Linux, the appearance on macOS. eza and
  zsh-patina only ever use the 8 ANSI colors, so they follow ghostty for free.
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
or the Ubuntu installer provides it. That makes `homie apply` enough to take a
base Arch install to a working Plasma session on the next boot.

No host currently carries the `arch` tag — cece moved to Arch and back — so all
of the above is kept deliberately but goes untested until one does.

## Tags

Auto-derived per host:
- Distro: `fedora`, `arch`, `ubuntu`, `debian`, or `macos`.
- Profile: `personal` or `work`, from `[profile].name`.
- Misc: CPU architecture (`amd64` / `arm64` — *not* the `arch` distro tag),
  short hostname, `root`, `container`.

Manual, set per-host via `[tags].extra`:
- `desktop` / `server` — workstation vs. headless.
- `kde`, `gnome` — desktop environment.

## Hosts

| host             | distro | profile  | extra tags   | `THEME` |
| ---------------- | ------ | -------- | ------------ | ------- |
| `coach`          | fedora | personal | desktop, kde | dark    |
| `uceap-dev01`    | fedora | work     | desktop, kde | light   |
| `UCEAP-M1022`    | macos  | work     | desktop      | light   |
| `cece`           | fedora | personal | desktop, kde | dark    |
| `nick`           | ubuntu | personal | server       | dark    |
| `winston`        | ubuntu | personal | server       | dark    |
| `uceap3-devbox`  | fedora | work     | server       | light   |

`THEME` is only the fallback — the three KDE hosts and the Mac follow their
desktop's light/dark setting at runtime instead. See [Theming](#theming).

## winston: services and backups

winston is the one host with system state outside `$HOME`, and Homie only
knows how to put files under `$HOME`. So `system.tag-winston/` mirrors the
paths under `/` that it owns, and the scripts in `scripts.tag-winston/` copy
those files into place, comparing first, the same way `28-asdbctl.sh`
installs its udev rule. Homie never reads `system.tag-winston/` itself. The
files are copied rather than symlinked: the units belong to root in `/etc`,
and compose resolves `./data` against the directory the compose file sits
in. Edit the repo copy, then re-apply.

- `29-readeck.sh` installs `/opt/readeck/docker-compose.yml`, brings the
  stack up only when the file changed, and makes sure `tailscale serve`
  publishes it at `https://winston.tail5aa588.ts.net:8443`.
- `30-backups.sh` installs and enables the backup timers. Everything runs
  overnight, America/New_York time:

  | time        | unit                     | what                                         |
  | ----------- | ------------------------ | -------------------------------------------- |
  | 01:00       | `ente-export`            | Ente photos → `~/Ente`                       |
  | 02:00       | `rclone-backup-seafile`  | `seafile:` → `b2:brattlebowl-winston-seafile` |
  | 02:00 Sun   | `readeck-export`         | `readeck export` → `~/Drive/Archive/readeck` |
  | 03:00       | `rclone-backup-drive`    | `~/Drive` → `b2:brattlebowl-winston-drive`   |
  | 04:00       | `rclone-backup-ente`     | `~/Ente` → `b2:brattlebowl-winston-ente`     |

Readeck is backed up through its own export rather than by copying its
data directory. The zip is plain JSON, HTML and images, so it can be restored
into something other than Readeck. Restoring into Readeck is
`readeck import -u <user> readeck-export.zip`; tested 2026-11-03.

Some of it is set up by hand and isn't tracked here, because it's secrets or
one-time state:

- `~/.config/rclone/rclone.conf`, which holds the `b2:` and `seafile:` remotes.
- The ente CLI (`/usr/local/bin/ente`) and its login under `~/.ente`.
- The B2 buckets' lifecycle rule. `rclone sync` leaves B2 an old version of
  every file it overwrites or deletes, and without a rule B2 keeps them
  forever. All three buckets delete those old versions 180 days later, set
  once per bucket with:

  ```sh
  rclone backend lifecycle b2:<bucket> -o daysFromHidingToDeleting=180
  ```

  Running `rclone backend lifecycle b2:<bucket>` with no options shows the
  current rule. Setting a rule replaces whatever rules the bucket had.
- The Seafile and arr-stack compose stacks in `/opt`. Their `.env` files
  hold secrets, so they haven't been ported yet.

## Secrets

Secrets are *not* rendered by Homie. They flow from 1Password at runtime:

- KDE login fires `~/.local/bin/op-env-session`, which `op inject`s `~/.config/zshrc-env.op-tmpl` and pushes the resulting env vars to the systemd user environment. Subsequent zsh sessions inherit them.
- SSH / non-KDE sessions fall back to `op inject` on shell startup (see `~/.zshrc.local`).
- All of this is work-only — the `home.tag-work/` tree gates it on the `work` tag.
