#!/bin/zsh

if [[ ! -v GH_TOKEN ]]; then
  gh auth login --hostname github.com --git-protocol https --scopes read:packages --web
fi
