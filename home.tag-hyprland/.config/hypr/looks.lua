-- Look and feel: geometry, decoration, animation.
--
-- Every colour comes from theme.lua, so this file is flavour-agnostic — a
-- `hyprctl reload` after the desktop flips light/dark re-runs it against the
-- other palette.

local theme = require("theme")

--------------------------------------------------------------- geometry ----
-- Gaps are tighter than the Hyprland default (5/20). On a 1536x960 logical
-- desktop, 20px outer gaps eat ~4% of the height for nothing; 10 reads as
-- deliberate space without costing a text line. gaps_out is asymmetric: the top
-- edge is smaller because waybar already sits there and its own margin adds to
-- this, and a matching 10 there would look like a 20px band.
hl.config({
  general = {
    gaps_in  = 4,
    gaps_out = { top = 4, right = 10, bottom = 10, left = 10 },

    border_size = 2,

    col = {
      -- A two-stop gradient at 45° is the single most recognisable Hyprland
      -- flourish, and mauve→blue is Catppuccin's own accent pairing. The active
      -- border is fully opaque so it reads at 2px; the inactive one is a flat
      -- surface tone rather than a dimmed accent, so unfocused windows recede
      -- instead of competing.
      active_border   = { colors = { theme.rgb("mauve"), theme.rgb("blue") }, angle = 45 },
      inactive_border = theme.rgba("surface0", 0.6),
    },

    resize_on_border       = true,
    extend_border_grab_area = 12,
    hover_icon_on_border   = true,

    allow_tearing = false,
    layout        = "dwindle",

    -- Floating windows snap to each other and to screen edges when dragged
    -- close. Cheap, and it's what makes a floating scratchpad feel placed
    -- rather than dropped.
    snap = { enabled = true, window_gap = 10, monitor_gap = 10 },
  },
})

------------------------------------------------------------- decoration ----
hl.config({
  decoration = {
    rounding = 10,
    -- 2 is a plain circular corner. Above that the curve turns squircle-ish
    -- (the iOS/macOS continuous corner); 3 is noticeably softer at this radius
    -- without reading as a mistake.
    rounding_power = 3,

    -- Focused windows are fully opaque — text has to stay legible. Only the
    -- unfocused ones get transparency, and 0.94 rather than the usual 0.85: at
    -- this screen size the wallpaper bleeding through unfocused terminals is
    -- distracting rather than pretty.
    active_opacity   = 1.0,
    inactive_opacity = 0.94,

    blur = {
      enabled = true,
      -- size 6 / passes 3 is the expensive-looking end of what an Iris Xe will
      -- do without the compositor dropping frames. new_optimizations is what
      -- keeps that true — it caches the blurred background instead of redoing
      -- it per frame.
      size    = 6,
      passes  = 3,
      new_optimizations = true,

      -- Blur the bar, the launcher and the notification centre too. These are
      -- layer surfaces, not windows, so they need saying explicitly — and they
      -- are most of what you actually see blurred.
      popups  = true,
      special = true,

      -- vibrancy pushes saturation back into what the blur washes out, which is
      -- what stops Catppuccin's pastels turning into grey mush behind a panel.
      vibrancy          = 0.17,
      vibrancy_darkness = theme.is_dark and 0.20 or 0.0,

      -- A little noise hides the banding a 3-pass blur leaves on flat colour.
      noise = 0.015,
    },

    shadow = {
      enabled = true,
      range   = 18,
      -- Higher render_power = tighter falloff. 3 keeps the shadow close to the
      -- window instead of a diffuse halo, which suits small screens.
      render_power = 3,
      -- Shadows are pure crust at low alpha in both flavours. On latte a black
      -- shadow would be the darkest thing on screen by a wide margin and look
      -- like a bug, so it's much lighter there.
      color        = theme.rgba("crust", theme.is_dark and 0.55 or 0.18),
      offset       = { 0, 2 },
    },

    -- Dim the workspace behind a modal or a fullscreen overlay, not behind
    -- every unfocused window — dim_inactive on a two-window tiling layout just
    -- makes half the screen muddy.
    dim_inactive = false,
    dim_modal    = true,
    dim_around   = 0.4,
    dim_strength = 0.15,
  },
})

------------------------------------------------------------- animations ----
-- Curves first, then the leaves that reference them. Names are arbitrary; these
-- match the ones Hyprland ships so the wiki's examples still apply.
hl.config({ animations = { enabled = true } })

hl.curve("easeOutQuint",   { type = "bezier", points = { { 0.23, 1 },    { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear",         { type = "bezier", points = { { 0, 0 },       { 1, 1 } } })
hl.curve("almostLinear",   { type = "bezier", points = { { 0.5, 0.5 },   { 0.75, 1 } } })
hl.curve("quick",          { type = "bezier", points = { { 0.15, 0 },    { 0.1, 1 } } })

-- A spring, not a bezier, for anything that moves a window. Springs settle
-- instead of stopping dead, which is the difference between "animated" and
-- "physical". Slightly stiffer and better damped than the shipped default so it
-- feels quick rather than bouncy.
hl.curve("snappy", { type = "spring", mass = 1, stiffness = 260, dampening = 26 })

hl.animation({ leaf = "global",        enabled = true, speed = 8,    bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.4,  bezier = "easeOutQuint" })

-- popin 90% rather than the default 87%: windows grow into place from nearly
-- full size, which at this screen size reads as a settle instead of a zoom.
hl.animation({ leaf = "windows",       enabled = true, speed = 4.8,  spring = "snappy" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.2,  spring = "snappy",       style = "popin 90%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 2.0,  bezier = "quick",        style = "popin 90%" })

hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.8,  bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.5,  bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.0,  bezier = "quick" })

-- Layer surfaces: the bar, rofi, swaync, wlogout, the on-screen keyboard. These
-- fade rather than slide — a launcher that flies in from an edge is the fastest
-- way to make a desktop feel slow.
hl.animation({ leaf = "layers",        enabled = true, speed = 3.8,  bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 2.4,  bezier = "linear",       style = "fade" })

-- Workspaces slide. This is the one place a directional animation earns itself:
-- it tells you which way you moved, and it's what a three-finger swipe is
-- physically dragging.
hl.animation({ leaf = "workspaces",    enabled = true, speed = 2.4,  bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 2.1,  bezier = "easeOutQuint", style = "slidefade 15%" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 2.4,  bezier = "easeOutQuint", style = "slidefade 15%" })

--------------------------------------------------------------- layouts ----
hl.config({
  dwindle = {
    -- Keep the split direction a window was created with when its sibling
    -- closes, instead of recomputing from the new aspect ratio.
    preserve_split = true,
    -- New windows open to the right/below rather than taking the master half.
    force_split    = 2,
  },

  master = {
    new_status = "master",
  },
})

------------------------------------------------------------------ misc ----
hl.config({
  misc = {
    -- No anime mascot, no Hyprland logo on an empty workspace. hyprpaper owns
    -- the background; this stops Hyprland drawing its own underneath.
    force_default_wallpaper = 0,
    disable_hyprland_logo   = true,

    -- Don't steal focus on its own — focus follows the mouse and explicit binds
    -- only. `focus_on_activate` off is what stops a background Electron app
    -- yanking the screen mid-sentence.
    focus_on_activate = false,

    -- Swallow the terminal when it launches a GUI app, and spit it back out
    -- when that app exits. `mpv video.mkv` from a shell shouldn't leave a dead
    -- terminal tiled next to the video.
    enable_swallow  = true,
    swallow_regex   = "^(com\\.mitchellh\\.ghostty)$",

    -- Keyboard focus stays with the window when a layer surface (waybar,
    -- swaync) is on screen, so clicking the bar doesn't steal input.
    layers_hog_keyboard_focus = false,

    -- Don't repaint windows nobody can see. Not zero — a completely frozen
    -- background window makes video thumbnails and progress bars stale.
    render_unfocused_fps = 10,
  },
})
