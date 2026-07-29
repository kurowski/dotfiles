-- Keybindings.
--
-- Layout follows the same logic throughout: SUPER alone acts on focus or opens
-- something, SUPER+SHIFT moves the thing that's focused, SUPER+CTRL resizes it.
-- Directions are available as both hjkl and arrows everywhere.

local mod = "SUPER"

-- Programs. Named once here so a change lands everywhere at once.
local terminal    = "ghostty"
local fileManager = "dolphin"
local browser     = "firefox"

-- rofi's colours come from a generated stylesheet: theme-mode concatenates
-- flavor-<mode>.rasi in front of theme.rasi and writes the result here. Passing
-- it with -theme (rather than importing it from config.rasi) sidesteps rofi
-- resolving a relative import against the dotfiles repo, since ~/.config/rofi
-- is symlinked into it. config.rasi still supplies behaviour.
local rofiTheme   = os.getenv("HOME") .. "/.local/state/theme-mode/rofi.rasi"
local launcher    = "rofi -show drun -theme " .. rofiTheme
local clipboard   = "cliphist list | rofi -dmenu -p clipboard -theme " .. rofiTheme
                    .. " | cliphist decode | wl-copy"

------------------------------------------------------------------- apps ----
hl.bind(mod .. " + Return",         hl.dsp.exec_cmd(terminal),    { desc = "Terminal" })
hl.bind(mod .. " + E",              hl.dsp.exec_cmd(fileManager), { desc = "File manager" })
hl.bind(mod .. " + B",              hl.dsp.exec_cmd(browser),     { desc = "Browser" })
hl.bind(mod .. " + R",              hl.dsp.exec_cmd(launcher),    { desc = "App launcher" })
hl.bind(mod .. " + Space",          hl.dsp.exec_cmd(launcher),    { desc = "App launcher" })
hl.bind(mod .. " + V",              hl.dsp.exec_cmd(clipboard),   { desc = "Clipboard history" })

----------------------------------------------------------------- window ----
hl.bind(mod .. " + Q",              hl.dsp.window.close(),                     { desc = "Close window" })
hl.bind(mod .. " + F",              hl.dsp.window.fullscreen(),                { desc = "Fullscreen" })
-- "maximized" keeps the bar and the gaps, unlike true fullscreen. The valid
-- modes are "fullscreen" and "maximized" — "maximize" is rejected.
hl.bind(mod .. " + SHIFT + F",      hl.dsp.window.fullscreen({ mode = "maximized" }), { desc = "Maximize" })
hl.bind(mod .. " + T",              hl.dsp.window.float({ action = "toggle" }), { desc = "Toggle floating" })
hl.bind(mod .. " + C",              hl.dsp.window.center(),                    { desc = "Centre window" })
hl.bind(mod .. " + P",              hl.dsp.window.pin({ action = "toggle" }),  { desc = "Pin above workspaces" })

-- Split direction. On backslash rather than J, which belongs to the direction
-- cluster below.
hl.bind(mod .. " + backslash",      hl.dsp.layout("togglesplit"),              { desc = "Toggle split direction" })

-- Directions. hjkl and arrows, identical in all three layers — focus with
-- SUPER, move with +SHIFT, resize with +CTRL.
--
-- These four letters are reserved for direction and nothing else. Binding
-- anything else to SUPER+L or SUPER+J means one of the two silently wins (the
-- later one) and the other key just stops working, with no error and nothing
-- in `hyprctl binds` to suggest a conflict — which is exactly what happened
-- here to focus-right and focus-down.
local dirs = {
  { key = "H", arrow = "left",  dir = "left"  },
  { key = "J", arrow = "down",  dir = "down"  },
  { key = "K", arrow = "up",    dir = "up"    },
  { key = "L", arrow = "right", dir = "right" },
}

for _, d in ipairs(dirs) do
  for _, k in ipairs({ d.key, d.arrow }) do
    hl.bind(mod .. " + " .. k,
      hl.dsp.focus({ direction = d.dir }),       { desc = "Focus " .. d.dir })
    hl.bind(mod .. " + SHIFT + " .. k,
      hl.dsp.window.move({ direction = d.dir }), { desc = "Move window " .. d.dir })
  end
end

-- Resize. relative = true makes x/y deltas rather than absolute sizes.
local step = 40
for key, d in pairs({
  H     = { x = -step, y = 0 }, L     = { x = step, y = 0 },
  K     = { x = 0, y = -step }, J     = { x = 0, y = step },
  left  = { x = -step, y = 0 }, right = { x = step, y = 0 },
  up    = { x = 0, y = -step }, down  = { x = 0, y = step },
}) do
  hl.bind(mod .. " + CTRL + " .. key,
    hl.dsp.window.resize({ x = d.x, y = d.y, relative = true }),
    { repeating = true, desc = "Resize window" })
end

------------------------------------------------------------- workspaces ----
for i = 1, 10 do
  local key = i % 10 -- workspace 10 sits on the 0 key
  hl.bind(mod .. " + " .. key,          hl.dsp.focus({ workspace = i }),        { desc = "Workspace " .. i })
  hl.bind(mod .. " + SHIFT + " .. key,  hl.dsp.window.move({ workspace = i }),  { desc = "Move to workspace " .. i })
end

hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })
hl.bind(mod .. " + Tab",        hl.dsp.focus({ workspace = "e+1" }), { desc = "Next workspace" })
hl.bind(mod .. " + SHIFT + Tab",hl.dsp.focus({ workspace = "e-1" }), { desc = "Previous workspace" })

-- Scratchpad.
hl.bind(mod .. " + S",         hl.dsp.workspace.toggle_special("magic"),          { desc = "Toggle scratchpad" })
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }), { desc = "Send to scratchpad" })

-- Mouse drag to move/resize. mouse:272 is left, 273 is right.
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

---------------------------------------------------------------- session ----
-- Lock. On SHIFT+Escape, not the usual SUPER+L — L is focus-right, and a
-- direction key is worth more than matching Windows' muscle memory. It sits
-- next to the session menu on plain Escape, which also offers Lock as its first
-- button, so there are two ways to reach it and neither costs a direction key.
hl.bind(mod .. " + SHIFT + Escape", hl.dsp.exec_cmd("hyprlock"), { desc = "Lock screen" })

-- wlogout takes its stylesheet on the command line for the same reason rofi
-- does — the repo copy is a symlink, so a relative import wouldn't resolve.
-- One row of five, which fits 1536px comfortably.
hl.bind(mod .. " + Escape",
  hl.dsp.exec_cmd("wlogout -b 5 -C " .. os.getenv("HOME") .. "/.local/state/theme-mode/wlogout.css"),
  { desc = "Session menu" })

-- Ends the whole uwsm-managed session, not just the compositor. `hl.dsp.exit()`
-- would kill Hyprland and leave the session's units running, which lands you at
-- a black screen rather than back at sddm.
hl.bind(mod .. " + SHIFT + M", hl.dsp.exec_cmd("uwsm stop"), { desc = "Log out" })

-------------------------------------------------------------- utilities ----
-- Screenshots. hyprshot writes to XDG_PICTURES_DIR and copies to the clipboard.
hl.bind("Print",                 hl.dsp.exec_cmd("hyprshot -m region"), { desc = "Screenshot region" })
hl.bind("SHIFT + Print",         hl.dsp.exec_cmd("hyprshot -m output"), { desc = "Screenshot screen" })
hl.bind(mod .. " + Print",       hl.dsp.exec_cmd("hyprshot -m window"), { desc = "Screenshot window" })

hl.bind(mod .. " + SHIFT + C",   hl.dsp.exec_cmd("hyprpicker -a"), { desc = "Pick colour to clipboard" })
hl.bind(mod .. " + N",           hl.dsp.exec_cmd("swaync-client -t -sw"), { desc = "Notification centre" })

-- These two live in ~/.local/bin, so they're spelled out in full.
--
-- ~/.config/uwsm/env puts that directory on the session PATH, which is the
-- general fix and covers rofi launching nvim and everything like it. Naming
-- these absolutely as well is not redundancy for its own sake: a bind is the
-- one caller with nowhere to report failure. `exec_cmd` on a command that isn't
-- found does nothing at all — no error, no notification, no log line — so the
-- symptom is a key that silently doesn't work, which is indistinguishable from
-- a bind that was never registered. Worth removing that failure mode from the
-- two commands this config owns.
local bin = os.getenv("HOME") .. "/.local/bin"

-- Flip the desktop between light and dark. Under Hyprland the authority is
-- gsettings (see theme-toggle and 28-hyprland-theme.sh) — the same setting
-- xdg-desktop-portal-gtk publishes and theme-mode watches, so this repaints the
-- terminal, nvim, tmux and the compositor together.
hl.bind(mod .. " + SHIFT + T", hl.dsp.exec_cmd(bin .. "/theme-toggle"), { desc = "Toggle light/dark" })

-- On-screen keyboard, for when the lid is folded back and there isn't one.
hl.bind(mod .. " + O",         hl.dsp.exec_cmd(bin .. "/osk-toggle"),   { desc = "On-screen keyboard" })

--------------------------------------------------------- hardware keys ----
-- locked = true so these still work on the lock screen; repeating = true so
-- holding them ramps instead of stepping once.
local hw = { locked = true, repeating = true }

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), hw)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      hw)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })

-- -e4 gives a perceptually even ramp rather than a linear one, and -n2 stops
-- the backlight reaching a genuinely black screen you can't recover from.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), hw)
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), hw)

local media = { locked = true }
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       media)
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   media)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), media)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), media)
