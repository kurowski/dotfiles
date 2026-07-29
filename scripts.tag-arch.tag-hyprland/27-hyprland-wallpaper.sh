#!/usr/bin/env bash
# Generate the pair of wallpapers the Hyprland session uses.
#
# Generated rather than downloaded, for the same reason everything else in this
# repo is declared rather than clicked: a wallpaper fetched from an image host
# is a dead link waiting to happen, and a binary checked into git is a binary
# checked into git. This produces the same two files on any machine from ~40
# lines of arithmetic.
#
# Written with Python's standard library only — zlib and struct are the whole of
# a PNG encoder for this kind of image. That avoids making imagemagick (and its
# dependency tree) a permanent part of the system for a job it does twice, ever.
#
# theme-mode symlinks whichever one matches the current flavour to
# ~/.local/state/theme-mode/wallpaper.png, which is the only path hyprpaper.conf
# and hyprlock.conf ever mention.
set -euo pipefail

out_dir="${XDG_DATA_HOME:-$HOME/.local/share}/wallpapers"
mkdir -p "$out_dir"

# Native panel resolution, not the 1.25-scaled logical size — hyprpaper wants
# real pixels, and anything smaller gets upscaled and looks soft.
readonly WIDTH=1920
readonly HEIGHT=1200

need_regen=0
for flav in latte mocha; do
  [[ -s "$out_dir/cece-$flav.png" ]] || need_regen=1
done

# Regenerate when this script is newer than what it produced, so editing the
# gradient below is enough to get a new wallpaper on the next apply.
if [[ $need_regen -eq 0 ]]; then
  for flav in latte mocha; do
    [[ "${BASH_SOURCE[0]}" -nt "$out_dir/cece-$flav.png" ]] && need_regen=1
  done
fi

if [[ $need_regen -eq 0 ]]; then
  echo "wallpapers up to date"
  exit 0
fi

python3 - "$out_dir" "$WIDTH" "$HEIGHT" <<'PY'
import math, random, struct, sys, zlib

out_dir, width, height = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])

def rgb(h):
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

# Three stops from each flavour's darkest surfaces, plus the accent for the
# bloom. Deliberately low-contrast: this sits behind translucent, blurred panels
# all day, and a busy wallpaper turns them to mud.
FLAVOURS = {
    "mocha": dict(a=rgb("11111b"), b=rgb("1e1e2e"), c=rgb("313244"),
                  accent=rgb("cba6f7"), bloom=0.16),
    # Latte inverts the ramp — its "deep" tone is the lightest one — and takes a
    # weaker bloom, because a saturated glow on a pale ground reads as a stain
    # rather than as light.
    "latte": dict(a=rgb("dce0e8"), b=rgb("eff1f5"), c=rgb("e6e9ef"),
                  accent=rgb("8839ef"), bloom=0.07),
}

def lerp(c0, c1, t):
    return tuple(c0[i] + (c1[i] - c0[i]) * t for i in range(3))

def png(path, rows):
    def chunk(tag, data):
        c = struct.pack(">I", len(data)) + tag + data
        return c + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)
    ihdr = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)  # 8-bit truecolour
    raw = b"".join(b"\x00" + r for r in rows)                     # filter type 0
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", ihdr))
        f.write(chunk(b"IDAT", zlib.compress(raw, 9)))
        f.write(chunk(b"IEND", b""))

for name, cfg in FLAVOURS.items():
    # Seeded per flavour so re-running produces byte-identical files; `hm
    # doctor` shouldn't report drift just because apply ran twice.
    rnd = random.Random(sum(cfg["a"]) + len(name))

    # Bloom centre, upper right — away from where waybar's clock and the
    # workspace pills sit, so the busiest part of the image is never behind the
    # busiest part of the bar.
    cx, cy = width * 0.74, height * 0.24
    radius = max(width, height) * 0.62

    rows = []
    for y in range(height):
        row = bytearray()
        fy = y / (height - 1)
        for x in range(width):
            fx = x / (width - 1)

            # Diagonal ramp, weighted toward vertical so it reads as light from
            # above rather than as a corner-to-corner wipe.
            t = fx * 0.35 + fy * 0.65
            col = lerp(cfg["a"], cfg["b"], min(1.0, t * 1.35)) if t < 0.74 \
                else lerp(cfg["b"], cfg["c"], (t - 0.74) / 0.26)

            # Radial accent bloom, falling off on a smoothstep so there is no
            # visible edge to the glow.
            d = math.hypot(x - cx, y - cy) / radius
            if d < 1.0:
                g = (1.0 - d) ** 2
                g = g * g * (3 - 2 * g) * cfg["bloom"]
                col = lerp(col, cfg["accent"], g)

            # A little noise. Eight-bit channels across a slow gradient band
            # badly on an IPS panel; ±1.5 levels of dither is invisible up close
            # and removes the banding entirely.
            n = rnd.uniform(-1.5, 1.5)
            row += bytes(max(0, min(255, int(v + n + 0.5))) for v in col)
        rows.append(bytes(row))

    png(f"{out_dir}/cece-{name}.png", rows)
    print(f"  wrote cece-{name}.png ({width}x{height})")
PY

echo "wallpapers generated in $out_dir"
