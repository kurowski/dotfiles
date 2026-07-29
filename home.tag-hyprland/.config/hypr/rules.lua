-- Window, workspace and layer rules.

------------------------------------------------------------ correctness ----
-- Both of these come from Hyprland's shipped config and exist to paper over
-- client misbehaviour rather than to express a preference.

hl.window_rule({
  -- Apps that maximise themselves on launch are assuming a floating desktop.
  -- Under a tiling layout the request is meaningless and just fights the layout.
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})

hl.window_rule({
  -- XWayland drag-and-drop creates a transient classless, titleless window. If
  -- it takes focus the drag is cancelled the moment it appears.
  name  = "fix-xwayland-drags",
  match = {
    class = "^$", title = "^$",
    xwayland = true, float = true, fullscreen = false, pin = false,
  },
  no_focus = true,
})

-------------------------------------------------------------- floating ----
-- Dialogs, pickers and small utilities. Tiling these makes a 1536x960 desktop
-- unusable — a volume mixer does not deserve half the screen.
-- The optional `(org\.[a-z]+\.)?` prefix is doing real work here. Under Wayland
-- an app-id is whatever the desktop entry is named, and the GTK apps have been
-- migrating to reverse-DNS: pavucontrol ships as
-- org.pulseaudio.pavucontrol.desktop with no StartupWMClass, so its app-id is
-- `org.pulseaudio.pavucontrol` and a bare `^pavucontrol$` silently never
-- matches. The others are still short names today and may not stay that way.
hl.window_rule({
  name  = "float-utilities",
  match = {
    class = "^(org\\.[a-zA-Z0-9]+\\.)?(pavucontrol|blueman-manager|nm-connection-editor|nwg-look|nwg-displays|qt6ct|kvantummanager)$",
  },
  float  = true,
  size   = { 820, 560 },
  center = true,
})

hl.window_rule({
  name  = "float-dialogs",
  match = { title = "^(Open|Open File|Open Folder|Save|Save As|Save File|Choose Files|Select a File|Confirm)( .*)?$" },
  float  = true,
  size   = { 900, 620 },
  center = true,
})

-- 1Password. Floating and centred, and never captured — the whole point of the
-- window is that its contents shouldn't leave the machine.
hl.window_rule({
  name  = "float-1password",
  match = { class = "^(1Password)$" },
  float  = true,
  center = true,
  size   = { 1000, 700 },
  no_screen_share = true,
})

-- Picture-in-picture: float, pin above every workspace, tuck it bottom-right,
-- and round it less — PiP windows draw their own corners.
hl.window_rule({
  name  = "pip",
  match = { title = "^(Picture-in-Picture)$" },
  float    = true,
  pin      = true,
  size     = { 480, 270 },
  move     = { "100%-500", "100%-320" },
  rounding = 6,
})

------------------------------------------------------------- appearance ----
-- Terminals get the blur to show through. Everything else stays opaque:
-- transparency behind a document or a browser is just harder to read.
--
-- opacity is a single space-separated string of "active inactive", not a table.
hl.window_rule({
  name  = "terminal-opacity",
  match = { class = "^(com\\.mitchellh\\.ghostty)$" },
  opacity = "0.94 0.88",
})

-- Fullscreen video and games: square corners, no shadow, and the idle timer
-- inhibited so the screen doesn't lock during a film.
hl.window_rule({
  name  = "fullscreen-media",
  match = { class = "^(mpv|io\\.github\\.celluloid|steam_app_.*)$" },
  rounding     = 0,
  no_shadow    = true,
  idle_inhibit = "fullscreen",
})

------------------------------------------------------------- workspaces ----
-- No "smart gaps" here, deliberately.
--
-- The usual trick is to drop gaps, border and rounding when a workspace holds a
-- single tiled window (`w[tv1]`), on the reasoning that one window has nothing
-- to be separated from. It reclaims about 20px on a 12" panel — and it also
-- means that most of the time, on a laptop where one maximised window *is* the
-- normal case, the desktop renders with no rounding, no gradient border and no
-- wallpaper visible anywhere. Every part of the look this config exists for is
-- switched off precisely when you're looking at it.
--
-- So single windows keep their frame. The one exception is real fullscreen,
-- which Hyprland already handles on its own: `f[1]` gets no decoration because
-- a fullscreen video with a mauve border around it would be worse.
hl.workspace_rule({ workspace = "f[1]", gaps_out = 0, gaps_in = 0 })

hl.window_rule({
  name  = "no-gaps-fullscreen",
  match = { float = false, workspace = "f[1]" },
  border_size = 0,
  rounding    = 0,
})

----------------------------------------------------------------- layers ----
-- Layer surfaces are the shell itself: bar, launcher, notifications, logout.
-- `blur` on a layer is what makes the bar translucent over the wallpaper rather
-- than a flat bar sitting on top of it.
for _, ns in ipairs({
  "waybar", "rofi",
  "swaync-control-center", "swaync-notification-window",
  "wlogout",
}) do
  hl.layer_rule({
    name  = "blur-" .. ns,
    match = { namespace = "^" .. ns .. "$" },
    blur = true,
    -- Don't blur what's already fully transparent in the surface's own CSS;
    -- without this the blur bleeds through the gaps between waybar's modules.
    ignore_alpha = 0.3,
  })
end

-- The on-screen keyboard appears and disappears constantly in tablet mode. An
-- animation on it reads as lag, and blurring a keyboard hurts the legibility of
-- the keycaps.
hl.layer_rule({
  name  = "osk",
  match = { namespace = "^wvkbd$" },
  no_anim = true,
})
