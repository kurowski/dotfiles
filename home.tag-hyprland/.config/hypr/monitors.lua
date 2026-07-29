-- Displays, and the touch/stylus mapping that has to follow them.

------------------------------------------------------------------ panel ----
-- The Framework 12's built-in panel: 12.2", 1920x1200, 60Hz. Scale 1.25 gives
-- 1536x960 logical, which is what Plasma had settled on — keeping the same
-- number means windows land at the same size in both sessions.
--
-- 1.25 is a fractional scale, so Wayland-native clients get a crisp buffer via
-- fractional-scale-v1 and XWayland ones get scaled up from 1x and look soft.
-- That's the tradeoff for a readable 12" panel; it's why env.lua pushes Qt,
-- Firefox and Electron onto Wayland wherever they'll go.
--
-- No `transform` here on purpose. iio-hyprland rewrites it at runtime when the
-- convertible is folded (see autostart.lua); a value baked in here would be
-- restored on every `hyprctl reload` and fight the accelerometer.
hl.monitor({
  output   = "eDP-1",
  mode     = "1920x1200@60",
  position = "auto",
  scale    = 1.25,
})

-- Anything plugged into the expansion ports. `preferred` + `auto` puts an
-- external display to the right at its native mode and 1x, which is right for
-- the desktop monitors this ever meets; nwg-displays can write something more
-- specific here if that stops being true.
hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = "auto",
})

--------------------------------------------------- touch + stylus mapping ----
-- A touchscreen reports absolute coordinates, so it has to be told which output
-- those coordinates belong to. Without this the digitizer spans the whole
-- layout the moment a second display is attached, and touches land on the wrong
-- screen — a laptop-only problem Plasma solves in its own settings.
--
-- Binding both to eDP-1 by name (rather than leaving it automatic) also means
-- the mapping survives a monitor being hotplugged.
hl.config({
  input = {
    touchdevice = { output = "eDP-1" },
    tablet      = { output = "eDP-1" },
  },
})
