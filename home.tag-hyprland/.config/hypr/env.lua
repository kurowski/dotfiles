-- Environment variables for the session.
--
-- hl.env sets these for processes Hyprland spawns, so it has to run before
-- autostart.lua. Anything a *login* needs before Hyprland exists (the session
-- type, the desktop name) comes from hyprland.desktop, not here.

local theme = require("theme")

------------------------------------------------------------------ cursor ----
-- Both size variables are set because the two cursor stacks disagree: XCURSOR_*
-- is what XWayland and older toolkits read, HYPRCURSOR_* is Hyprland's own
-- hyprcursor format. Setting one and not the other gets you a correctly-sized
-- cursor over half the screen.
--
-- 24 is deliberately not scaled up. The panel is 1920x1200 at scale 1.25, so
-- Hyprland already multiplies this; hardcoding 32 here would land at an
-- effective 40.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XCURSOR_THEME", theme.cursor_theme)
hl.env("HYPRCURSOR_THEME", theme.cursor_theme)

--------------------------------------------------------------------- qt ----
-- Plasma themes Qt through its own platform integration, which isn't running
-- here. qt6ct + Kvantum replace it, and the platform plugin has to prefer
-- wayland or every Qt app silently lands on XWayland and looks blurry at 1.25.
--
-- The `;xcb` fallback matters for the Qt5 apps that still ship without the
-- wayland plugin — without it they refuse to start rather than falling back.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")

------------------------------------------------------------------ gtk/etc ----
-- GTK reads its theme from gsettings (see 26-hyprland-theme.sh), not from an
-- env var, so there's nothing to set here for appearance.
hl.env("MOZ_ENABLE_WAYLAND", "1")

-- Electron apps — Claude Desktop, VS Code — default to X11 unless told. `auto`
-- lets them pick Wayland when the session offers it, which is the one that
-- respects fractional scaling.
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- Java/Swing apps assume a reparenting WM and come up blank under tiling ones.
hl.env("_JAVA_AWT_WM_NONREPARENTING", "1")
