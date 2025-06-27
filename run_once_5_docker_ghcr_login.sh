#!/bin/zsh

gh auth token | docker login ghcr.io --username $(gh api user --jq .login)$ --password-stdin