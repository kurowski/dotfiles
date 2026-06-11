-- rg/fd skip dotfiles by default, which hides most of a dotfiles-managed
-- $HOME from the pickers. (AstroNvim's <Leader>ff passes hidden explicitly
-- based on git-repo detection, so `files` here only affects pickers that
-- don't override it, e.g. the explorer-scoped ones.)
return {
  "folke/snacks.nvim",
  opts = {
    picker = {
      sources = {
        files = { hidden = true },
        grep = { hidden = true },
        grep_word = { hidden = true },
        smart = { hidden = true },
      },
    },
  },
}
