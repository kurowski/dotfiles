#!/bin/zsh

if ! command -v ujust &> /dev/null; then
	exit 0 # we're not on a universal blue descendant
fi

ujust --explain setup-luks-tpm-unlock
ujust --explain dx-group
ujust --explain install-fonts
ujust --explain aurora-cli