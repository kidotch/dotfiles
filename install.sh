#!/usr/bin/env bash
set -e

ln -sf $(pwd)/tmux/tmux.conf ~/.tmux.conf
ln -sf $(pwd)/scripts/setup-locale-tmux.sh ~/setup-locale-tmux.sh

echo "Dotfiles installed."
