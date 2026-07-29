-- Hyprland on cece (Framework Laptop 12, convertible).
--
-- Lua rather than the classic hyprland.conf: hyprlang was deprecated in 0.55 and
-- the wiki is now Lua-first, so this is the syntax the docs describe and the one
-- that won't need rewriting. `hyprland.lua` wins over `hyprland.conf` when both
-- exist — there is no hyprland.conf here.
--
-- Split across files, each required below. Hyprland puts the config directory on
-- package.path, so these are plain module names.
--
-- This session runs alongside Plasma, not instead of it; cece carries both the
-- `kde` and `hyprland` tags and sddm offers both. Anything that would make the
-- Plasma session worse doesn't belong in this tree.

require("env")        -- environment variables (must precede anything that spawns)
require("monitors")   -- eDP-1, and the touch/stylus mapping that follows it
require("looks")      -- general, decoration, animations
require("input")      -- keyboard, touchpad, touchscreen, gestures
require("binds")      -- keybindings
require("rules")      -- window, workspace and layer rules
require("autostart")  -- hyprland.start handlers
