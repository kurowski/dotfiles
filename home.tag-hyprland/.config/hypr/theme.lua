-- Catppuccin palettes and the light/dark resolution for the Hyprland session.
--
-- This is the Hyprland-side counterpart to ~/.local/bin/theme-mode. It reads the
-- same state file that .zshrc and nvim key off, so the compositor agrees with
-- the terminal without either one asking the portal twice.
--
-- Unlike fzf and lazygit — which get one file per flavour because their consumer
-- can only be pointed at a path — Lua can branch, so both palettes live here and
-- the table is picked at load time. Same principle as the rest of the repo (data
-- per flavour, switch at runtime), expressed the way the language allows.
--
-- How a live theme change reaches the compositor: theme-mode writes the state
-- file, then runs `hyprctl reload`. That re-executes this config from the top,
-- so read_flavor() runs again and every colour below is recomputed. There is no
-- generated file and nothing to keep in sync.

local M = {}

-- The accent every component keys off. Catppuccin ships fourteen; mauve is the
-- flavour's default and the one the GTK/Kvantum/SDDM packages are pinned to in
-- 25-sddm.sh and 26-hyprland-theme.sh. Change it in one place and the whole
-- session follows, but the *packages* are per-accent, so a change here wants a
-- matching change there.
M.accent = "mauve"

-- https://github.com/catppuccin/catppuccin — hex without the leading '#', since
-- Hyprland wants rgb()/rgba() and the CSS consumers want '#'. to_css() and
-- rgba() below add whichever prefix the target needs.
local palettes = {
  latte = {
    rosewater = "dc8a78", flamingo = "dd7878", pink     = "ea76cb",
    mauve     = "8839ef", red      = "d20f39", maroon   = "e64553",
    peach     = "fe640b", yellow   = "df8e1d", green    = "40a02b",
    teal      = "179299", sky      = "04a5e5", sapphire = "209fb5",
    blue      = "1e66f5", lavender = "7287fd",
    text      = "4c4f69", subtext1 = "5c5f77", subtext0 = "6c6f85",
    overlay2  = "7c7f93", overlay1 = "8c8fa1", overlay0 = "9ca0b0",
    surface2  = "acb0be", surface1 = "bcc0cc", surface0 = "ccd0da",
    base      = "eff1f5", mantle   = "e6e9ef", crust    = "dce0e8",
  },
  mocha = {
    rosewater = "f5e0dc", flamingo = "f2cdcd", pink     = "f5c2e7",
    mauve     = "cba6f7", red      = "f38ba8", maroon   = "eba0ac",
    peach     = "fab387", yellow   = "f9e2af", green    = "a6e3a1",
    teal      = "94e2d5", sky      = "89dceb", sapphire = "74c7ec",
    blue      = "89b4fa", lavender = "b4befe",
    text      = "cdd6f4", subtext1 = "bac2de", subtext0 = "a6adc8",
    overlay2  = "9399b2", overlay1 = "7f849c", overlay0 = "6c7086",
    surface2  = "585b70", surface1 = "45475a", surface0 = "313244",
    base      = "1e1e2e", mantle   = "181825", crust    = "11111b",
  },
}

-- The file ~/.local/bin/theme-mode writes last, once everything it implies is
-- already on disk. Missing means the host hasn't been applied yet, in which case
-- dark is the safer guess than a white flash — the same fallback theme-mode uses.
local function read_flavor()
  local state = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local fh = io.open(state .. "/theme-mode/mode", "r")
  if not fh then return "mocha" end
  local mode = fh:read("l")
  fh:close()
  return mode == "light" and "latte" or "mocha"
end

M.flavor = read_flavor()
M.is_dark = M.flavor == "mocha"
M.c = palettes[M.flavor]

-- Hyprland colour literals. Hex here is RRGGBB; alpha is a 0-1 float appended as
-- the two-hex-digit AA that rgba() expects.
function M.rgb(name) return "rgb(" .. M.c[name] .. ")" end
function M.rgba(name, alpha)
  return string.format("rgba(%s%02x)", M.c[name], math.floor(alpha * 255 + 0.5))
end

-- For the GTK/Qt/cursor names that embed both flavour and accent.
M.gtk_theme    = "catppuccin-" .. M.flavor .. "-" .. M.accent .. "-standard+default"
M.cursor_theme = "catppuccin-" .. M.flavor .. "-" .. M.accent .. "-cursors"
M.kvantum      = "catppuccin-" .. M.flavor .. "-" .. M.accent

return M
