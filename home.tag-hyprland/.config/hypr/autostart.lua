-- Things that start with the session.
--
-- Most of the session's daemons are *not* here. hyprpaper, hypridle, swaync and
-- hyprpolkitagent each ship a systemd user unit, and 26-hyprland-session.sh
-- binds them to wayland-session@Hyprland.target so systemd starts them — with
-- restart-on-failure and proper ordering — and so they stay out of the Plasma
-- session. Adding them here as well would start each one twice.
--
-- What's left is the handful of things with no unit of their own.

hl.on("hyprland.start", function()
  -- First, before anything else: hand the session environment to systemd and
  -- D-Bus. uwsm starts the compositor, but only the compositor can know
  -- WAYLAND_DISPLAY and HYPRLAND_INSTANCE_SIGNATURE once it's up. Until this
  -- runs, every unit with ConditionEnvironment=WAYLAND_DISPLAY — including
  -- theme-mode.service — refuses to start.
  hl.exec_cmd("uwsm finalize")

  -- Clipboard history. Two watchers because wl-paste tracks one MIME class
  -- each: text and images. cliphist stores, rofi reads it back (SUPER+V).
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")

  -- Auto-rotation is *not* here. hypr-autorotate.service handles it, bound to
  -- wayland-session@hyprland.desktop.target like the other daemons, so it gets
  -- restart-on-failure and stops cleanly with the session.
end)
