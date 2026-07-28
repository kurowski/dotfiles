-- Catppuccin flavor follows the mode resolved by ~/.local/bin/theme-mode.
--
-- Neovim guesses 'background' at startup by querying the terminal (OSC 11),
-- but that query has to survive tmux to be trustworthy, so read the state file
-- instead and only fall back to whatever nvim worked out on its own.
--
-- Nothing here is host-specific: on a pinned light/dark host the state file
-- just never changes.

local function read_mode()
  local state = vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")
  local f = io.open(state .. "/theme-mode/mode", "r")
  if not f then return nil end
  local mode = vim.trim(f:read("l") or "")
  f:close()
  if mode == "light" or mode == "dark" then return mode end
  return nil
end

local mode = read_mode()
if mode then vim.o.background = mode end

local function flavour()
  return vim.o.background == "dark" and "mocha" or "latte"
end

-- `theme-mode reload` pushes `set background=...` into running instances over
-- --remote-expr. That only flips the option; this is what turns it into a
-- repaint. Catppuccin resolves "auto" once at load and then caches the result,
-- so name the flavor explicitly rather than reloading "catppuccin" and hoping.
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  desc = "Re-theme when the desktop switches between light and dark",
  callback = function()
    vim.schedule(function()
      pcall(vim.cmd.colorscheme, "catppuccin-" .. flavour())
    end)
  end,
})

return {
  {
    "catppuccin",
    opts = {
      flavour = "auto", -- follows vim.o.background, set above
      background = { light = "latte", dark = "mocha" },
    },
  },
  {
    "AstroNvim/astroui",
    opts = { colorscheme = "catppuccin-" .. flavour() },
  },
}
