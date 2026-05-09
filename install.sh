#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

mkdir -p "$HOME/.config"

ln -sfn "$DOTFILES/.emacs.d" "$HOME/.emacs.d"
ln -sfn "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
