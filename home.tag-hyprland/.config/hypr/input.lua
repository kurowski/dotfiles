-- Keyboard, pointer, touchscreen and gestures.
--
-- The keyboard and touchpad settings here deliberately mirror what Plasma is
-- configured with (kxkbrc Options, kcminputrc NaturalScroll/ClickMethod), so
-- the two sessions feel identical. Changing one without the other is how you
-- end up distrusting your own laptop.

hl.config({
  input = {
    kb_layout = "us",
    -- CapsLock is Escape. scripts.tag-kde/04-kde-capslock.sh sets the same
    -- thing via kxkbrc for the Plasma session; this is the Hyprland half of
    -- that pair, and they have to move together.
    kb_options = "caps:escape",

    -- 1 = focus follows the mouse, but only the *window* under it — moving the
    -- pointer across a window doesn't raise it or steal keyboard focus from a
    -- fullscreen app. 2 would refocus on every motion event, which fights
    -- click-to-type dialogs.
    follow_mouse = 1,
    -- Don't refocus when the pointer merely passes over a window on its way
    -- somewhere else.
    follow_mouse_threshold = 8,

    -- 0 = libinput's own acceleration, unmodified. The Framework's touchpad is
    -- well-tuned out of the box; this exists to say the default is deliberate.
    sensitivity = 0,

    touchpad = {
      -- Matches kcminputrc NaturalScroll=true.
      natural_scroll = true,
      -- Matches kcminputrc ClickMethod=2 (clickfinger): a two-finger press is
      -- right-click and a three-finger press is middle-click, rather than
      -- dividing the pad into button zones.
      clickfinger_behavior = true,
      tap_to_click         = true,
      tap_and_drag         = true,
      -- Palm rejection while typing. Essential on a 12" chassis where the pad
      -- sits directly under where your hands rest.
      disable_while_typing = true,
    },

    -- The touchscreen. `transform` is left unset for the same reason the
    -- monitor's is (see monitors.lua) — iio-hyprland rewrites it on fold, and a
    -- baked-in value would be restored on every reload and fight rotation.
    touchdevice = {
      enabled = true,
    },
  },
})

------------------------------------------------------------ touch tuning ----
-- Options for the swipe behaviour itself. The bindings that *use* them are the
-- hl.gesture() calls below; this section only shapes how they feel.
hl.config({
  gestures = {
    -- The convertible's whole point: swiping workspaces with a finger on the
    -- screen, not just on the touchpad. Off by default because it's wrong on a
    -- non-touch laptop.
    workspace_swipe_touch = true,

    -- Distance (px) a swipe must travel to complete. Lower than the 300
    -- default because 1536 logical px is a short screen to drag across.
    workspace_swipe_distance = 220,

    -- Let a fast flick complete the switch even if it didn't cover the
    -- distance, and require a swipe to be 60% of the way before it commits
    -- rather than snapping back.
    workspace_swipe_min_speed_to_force = 20,
    workspace_swipe_cancel_ratio       = 0.4,

    -- Once a swipe is going horizontally, keep it horizontal. Without this, a
    -- slightly diagonal finger drag on a touchscreen wobbles between axes.
    workspace_swipe_direction_lock           = true,
    workspace_swipe_direction_lock_threshold = 10,

    -- Don't invent a new workspace by swiping past the last one; that turns a
    -- fat-fingered swipe into an empty desktop you have to find your way back
    -- from.
    workspace_swipe_create_new = false,
    workspace_swipe_forever    = true,
  },
})

--------------------------------------------------------------- gestures ----
-- Three fingers horizontally: previous/next workspace. The one gesture worth
-- having, and the one workspace animations in looks.lua are drawn for — the
-- slide follows the finger 1:1.
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})

-- Four fingers horizontally: drag the *window* to the neighbouring workspace
-- instead of just following it there.
hl.gesture({
  fingers   = 4,
  direction = "horizontal",
  action    = "move",
})

-- Four fingers up: fullscreen the focused window. Down is deliberately not
-- bound to `close` — a four-finger flick is far too easy to do by accident for
-- something destructive.
hl.gesture({
  fingers   = 4,
  direction = "up",
  action    = "fullscreen",
})

-- No pinch gestures, on purpose. Pinch is how you zoom inside a browser, a PDF,
-- an image viewer or a map — on a touchscreen those matter far more than
-- anything the compositor could do with it, and a compositor-level pinch would
-- swallow the event before the app ever saw it.
