#!/bin/zsh

if command -v docker &> /dev/null; then
  gh auth token | docker login ghcr.io --username $(gh api user --jq .login)$ --password-stdin
fi
