#!/bin/zsh

if ! command -v ujust &> /dev/null; then
	exit 0 # we're not on a universal blue descendant
fi

ujust --explain setup-luks-tpm-unlock
ujust --explain dx-group
ujust --explain install-fonts
ujust --explain aurora-cli
ujust --explain ptyxis-transparency 1

# temporarily putting this here for lack of a better place
brew install devcontainer doxx lazygit marp-cli

# this is all for lazyvim
brew install \
  ast-grep \
  lazygit \
  markdown-toc \
  markdownlint-cli2 \
  prettier \
  vifm

# other CLI quality of life
brew install \
  vivid
