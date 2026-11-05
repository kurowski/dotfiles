# AGENTS.md

## Overview

This is a **Homie** dotfiles repo — a declarative workstation configuration system.
The tool `homie` (Homie) reads `homie.toml` + per-host overlays and reconciles packages,
dotfiles, and post-install scripts against the running machine.

**Key architectural concept**: Everything is gated by **tags** (distro, profile,
host tags like `desktop`/`server`, `work`/`personal`, `kde`/`gnome`). Tags determine
which packages, dotfiles, and scripts apply to a given host. Tags compose via AND
(multi-tag directories) and trigger different branches in `.tmpl` files.

## Essential commands

```bash
homie apply        # Full reconcile: packages + dotfiles + scripts
homie home         # Refresh dotfile symlinks + render .tmpl templates only (skip packages)
homie doctor       # Check for broken symlinks / drift
homie status       # Read-only summary of what homie sees
homie run <script> # Run a single post-install script manually
```

**Rebuild the host**: `homie apply --skip-packages && homie apply` (process: skip
packages first to pick up any new package declarations without errors, then
full apply with the refreshed package list).

## Core file layout

| Path | Purpose |
|------|---------|
| `homie.toml` | Base config: package sets per distro, defaults, vars. Deep-merged with host overlays. |
| `hosts/<hostname>.toml` | Per-host overlay. Keys: `[tags].extra`, `[user]`, `[profile]`, `[vars]`, `[packages."tag:X"]`. |
| `home/` | Always-applied dotfiles. Plain files become symlinks into the repo. |
| `*.tmpl` | Go-template files rendered by Homie on `homie apply`. Uses `{{ .Name }}`, `{{ .Email }}`, `{{ .Vars.THEME }}`, `{{ if hasTag "work" }}...{{ else }}...{{ end }}`. |
| `*.op-tmpl` | 1Password inject template — NOT rendered by Homie. `op inject` processes these at runtime. |
| `home.tag-X/` | Dotfiles applied only when tag X is active. Multi-tag = AND: `home.tag-work.tag-kde/`. |
| `scripts/` | Post-package install scripts. Run **after** packages are installed, in numerical order. |
| `scripts.pre-*.sh` | Pre-package scripts. Run **before** package install. Used for adding third-party repos. |
| `scripts.tag-X/` | Tag-gated scripts. Same AND rules as `home.tag-X/`. |

## Homie template syntax

Homie uses Go templates with custom helpers. The `.tmpl` extension triggers template
processing by Homie. Key patterns:

```
# Variable interpolation
{{ .Vars.THEME }}          # From [vars]
{{ .Name }}                 # From [profile] -> system username
{{ .Email }}               # From [user] or [profile]

# Conditionals (tags derived from [profile].name, hostname, and [tags].extra)
{{ if hasTag "work" }}latte{{ else }}mocha{{ end }}
{{ if hasTag "work" }}light{{ else }}dark{{ end }}

# Whitespace control: {{- trims preceding whitespace, -}} trims trailing
{{- if hasTag "work" -}}...{{- end }}
```

**Double-brace rule**: `{{ }}` is for Homie templates. `{{ }}` inside `.op-tmpl`
files is NOT Homie — those are 1Password secret references (e.g.,
`{{ op://vault/item/field }}`).

## Tags

Tags are the dispatch mechanism. They determine every decision: dotfiles, scripts,
packages, template branches.

**Auto-derived**: fedora, ubuntu, debian, macos, arch, short-hostname, personal or
work (from `[profile].name`), container, root.

**Manual** (set in host file `[tags].extra`): `desktop`/`server`, `kde`/`gnome`.

**Tag usage across the codebase**:
- `home.tag-work/` → files only on work machines
- `scripts.tag-personal/` → scripts only for personal profile
- `[packages."tag:desktop"]` → package matrix scoped to hosts with `desktop` tag
- `{{ if hasTag "work" }}` → template conditional branching
- Tag filters like `"tag:personal.tag:ubuntu"` → AND: both must match

## Theme system

Two themes via Catppuccin: **Latte** (light, on `work` hosts) and **Mocha** (dark,
on `personal` hosts).

**How it works**:
1. The `work` tag (from `[profile].name = "work"`) triggers light/Latte.
2. The `personal` profile triggers dark/Mocha.
3. Every tool's config references this distinction:
   - `.tmpl` files: `{{ if hasTag "work" }}latte{{ else }}mocha{{ end }}`
   - Ghostty: `theme = {{ if hasTag "work" }}Catppuccin Latte{{ else }}Catppuccin Mocha{{ end }}`
   - starship.toml: `palette = 'catppuccin_{{ if hasTag "work" }}latte{{ else }}mocha{{ end }}'`
   - nvim colorscheme: `"catppuccin-{{ if hasTag "work" }}latte{{ else }}mocha{{ end }}"`

**Work tag origin**: A host has the `work` tag when `hosts/<host>.toml` sets
`[profile] name = "work"`, OR when it inherits the `work` profile from the base config.

## Post-install scripts (`scripts/`)

- **All scripts must be idempotent** — they guard with existence checks
  (`command -v`, `test -f`, etc.) and exit 0 if already done.
- **Naming**: numeric prefix for ordering (e.g., `01-rust-toolchain.sh`).
- **Tag-gating**: Scripts in `scripts.tag-work/` auto-gated; runtime checks
  inside the script use `$HOMIE_TAGS` for more granular control:
  ```bash
  case ",$HOMIE_TAGS," in *,container,*) exit 0 ;; esac
  ```
- **Secret integration**: Uses `op read` from 1Password CLI when runtime secrets
  needed (see 1Password section below).

## 1Password secret flow

Secrets are NOT rendered by Homie. The flow:

1. **At package install/setup time**: Some scripts (`06-atuin-sync.sh`) call
   `op read` to inject 1Password-stored secret values. This flows through
   the desktop app's running CLI integration.

2. **At runtime (KDE work machines)**:
   - KDE login fires `~/.local/bin/op-env-session` via autostart desktop file
   - That script runs `op inject` on `~/.config/zshrc-env.op-tmpl`
   - Environment variables land in the systemd user environment
   - `~/.zshrc.local` (from `home.tag-work/.zshrc.local.tmpl`) reads from
     systemd user env on each shell start
   - Fallback: `op inject` called directly if systemd env not available

3. **At dartime (non-KDE/SSH)**: `~/.zshrc.local` falls back to `op inject`
   if the systemd user environment doesn't have `$OP_SESSION_LOADED`.

**Container detection**: `.zshrc.local.tmpl` checks for `/.dockerenv`,
`$REMOTE_CONTAINERS`, and `$CODESPACES` and skips `op inject` entirely in
containers (would hang waiting for desktop app).

## Package management

Packages are declared in `homie.toml` under `[packages]` sections, scoped by
distro and optional tag filter:

```toml
[packages]                          # Base packages for all hosts
fedora = ["package1", "package2"]
debian = ["package1"]
macos = ["package1"]

[packages."tag:desktop"]            # Only on hosts with desktop tag
fedora = ["extras"]

[packages."tag:personal.tag:ubuntu".snap]  # Snap backend, AND-tagged
all = ["gimp"]
```

- `macos` always means brew (native macOS manager).
- Append `/cask` to mark brew cask: `"ghostty/cask"`.
- Other backends: `[packages."tag:X".flatpak]`, `[packages."tag:X".snap]`.
- `all` key means apply regardless of distro (for backend-scoped blocks).
- If the backend tool is missing, the block is skipped with a warning.

## Script patterns

**Guard clauses first** — every script starts with `set -euo pipefail` and runs
the minimum check before proceeding. Given `$HOMIE_TAGS` is available at runtime:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Skip for containers (no display, no desktop integration)
case ",$HOMIE_TAGS," in *,container,*) exit 0 ;; esac

# Idempotency check
command -v starship >/dev/null 2>&1 && exit 0

# Proceed with installation
```

**Pre-scripts** (`scripts/pre-*.sh`): Run before package install. Add repos via
distro-specific package managers (dnf copr, apt-add-repository, etc.) to make
packages visible to homie. Also idempotent.

## Host configuration files (`hosts/<hostname>.toml`)

These override/extend the base `homie.toml`. Minimum structure:

```toml
[profile]
name = "personal"  # or "work"

[tags]
extra = ["desktop", "kde"]  # additional tags beyond auto-derived ones

[vars]
THEME = "dark"
OP_ACCOUNT = "my"  # 1Password account for op CLI
ATUIN_SYNC = "false"
```

Work hosts also set `[user] email` as override (different from base config).

## Gotchas & non-obvious behavior

**No-tt flag**: When testing homie templates locally, use `--no-tty`
to skip tty formatting. Script commands sometimes need it: `homie --no-tty apply`.

**Three file types — don't confuse them**:
When editing `home/`, there are three distinct file processing pipelines:
- `.tmpl` → Homie Go templates rendered by `homie home` using Go template syntax
- `.op-tmpl` → 1Password `op inject` templates. NOT rendered by Homie
- Plain files → direct symlinks, no rendering of any kind
  
These must never be mixed up. A `.tmpl` file contains `{{ }}` that is
processed by Homie (which uses Go templates with custom helpers like `hasTag`
and `.Vars.VARIABLE`). An `.op-tml` file contains `{{ op://... }}` references
for 1Password. A plain file is just wrapped in a symlink.

**Kubernetes version pinning** (`scripts.tag-fedora/pre-01-fedora-repos.sh:63-64`):
Kubernetes repo is pinned per minor SDK skew policy. When updating to a new
Kubernetes release, the base URL in this script needs `v1.34` bumped. The
comment in the script documents this requirement.

**HashiCorp repo lag** (same script, lines 75-88):
HashiCorp's Fedora repository often lags 1-2 Fedora releases. The script
pins the base URL to `fedora/43` even on newer Fedora versions. The embedded
comment in the script explains why.

**Container hosts**: Machines with the `container` tag skip most scripts due to
a `case` gate checking `*,container,*` in `$HOMIE_TAGS`. Container environments
get secrets via devcontainer CLI's containerEnv/remoteEnv instead of 1Password.

**1Password account names**: The `OP_ACCOUNT` variable ("my", "team-uceap") refers
to 1Password account names, not Linux user names. This is set per-host in
`hosts/<host>.toml` under `[vars]`.

**Theme system — Latte for work, Mocha for personal**:
Catppuccin themes are collected from upstream repos (catppuccin/eza, catppuccin/tmux,
catppuccin-starship, etc.) and rendered per-host. The work/personal split determines
the flavor:
- Work hosts → Latte (light)
- Personal hosts → Mocha (dark)

This is controlled by `{{ if hasTag "work" }}` template conditionals in every
theme-referencing tool (ghostty, tmux, starship, lazygit, nvim, fzf, bat).

**Dotfile management — no deletions**:
`homie home` creates and updates symlinks from `home/` into the actual home
directory. It does NOT delete old symlinks remove points. Use `homie doctor` to
find drift and manually remove stale symlinks.

**"Available but not selected" in `homie status`**:
When `homie status` shows packages as available but not selected, this is expected
for hosts with `container` or `server` tags that skip many desktop package
selections. Not an error, not a warning.

**Symlink-only files**: Files in `home/` without `.tmpl` or `.op-tmpl` extension
are symlinked as-is with no template processing of any kind.

## Working with templates

When editing `.tmpl` template files:

1. The template receives Homie's runtime context — `{{ .Name }}`,
   `{{ .Email }}`, `{{ .Vars.VARIABLE_NAME }}`, and the `hasTag` function.
2. Fast iteration: `homie home` re-renders all templates and updates symlinks (< 5s).
3. After changing any file in `home/`, run `homie home` to create/update symlinks.
4. Test template syntax by comparing against other template files for correctness
   — the patterns are highly consistent across the codebase.

## Editing host configuration

When editing `hosts/*.toml` or `homie.toml`:
- Package declarations: Ensure they match actual available packages for the distro.
  Test with `homie status` to see resolved package lists.
- Variable values: `[vars]` in host file override base `[vars]` in homie.toml.
- Tags: `extra` in host file appends to auto-detected tags. Check `homie status` to
  verify what tags a host ends up with.
- Multi-tag package blocks (e.g., `[packages."tag:personal.tag:ubuntu"]`) require
  ALL listed tags to match — they use AND logic.
- On macOS, the default package manager is brew. Append `/cask` to a package name
  to mark it as a brew cask (e.g., `"ghostty/cask"`).
- Flatpak packages go in dedicated blocks: `[packages."tag:X".flatpak] all = [...]`.
  Snap packages likewise: `[packages."tag:X".snap] all = [...]`.
