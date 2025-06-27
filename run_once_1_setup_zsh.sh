#!/bin/zsh

echo "Changing default shell to zsh..."
sudo usermod -s /bin/zsh $(whoami)

# let's try life without omz just to see
# sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
