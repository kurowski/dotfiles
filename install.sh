#!/usr/bin/env zsh
DOTFILES=$(dirname $(realpath $0))

git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

[[ ! -f ~/.zshrc ]] || mv ~/.zshrc ~/.zshrc.orig
ln -s $DOTFILES/.zshrc ~

[[ ! -f ~/.p10k.zsh ]] || mv ~/.p10k.zsh ~/.p10k.zsh.orig
ln -s $DOTFILES/.p10k.zsh ~

[[ ! -f ~/.config/atuin/config.toml ]] || mv ~/.config/atuin/config.toml ~/.config/atuin/config.toml.orig
mkdir -p ~/.config/atuin
ln -s $DOTFILES/atuin/config.toml ~/.config/atuin
if command -v atuin &> /dev/null && [ -v ATUIN_PASSWORD ] && [ -v ATUIN_KEY ]; then
  atuin login -u bkurowski -p "$ATUIN_PASSWORD" -k "$ATUIN_KEY"
fi

[[ ! -f ~/.config/gh-copilot/config.yml ]] || mv ~/.config/gh-copilot/config.yml ~/.config/gh-copilot/config.yml.orig
mkdir -p ~/.config/gh-copilot
ln -s $DOTFILES/gh-copilot/config.yml ~/.config/gh-copilot

if command -v defaults &> /dev/null; then
  defaults write com.apple.Safari UserStyleSheetLocationURLString -string "$DOTFILES/Safari/stylesheet.css"
fi
