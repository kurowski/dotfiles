#!/bin/zsh

if command -v onedrive &> /dev/null; then
  onedrive
  systemctl --user enable onedrive
  systemctl --user start onedrive
fi
