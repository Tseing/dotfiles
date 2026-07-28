#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

mkdir -p \
  "$HOME/.config" \
  "$HOME/.config/enchant" \
  "$HOME/.config/zathura"

ln -sfn "$DOTFILES/.emacs.d" "$HOME/.emacs.d"
ln -sfn "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
ln -sfn "$DOTFILES/.config/enchant/personal.dic" "$HOME/.config/enchant/en_US.dic"
ln -sfn "$DOTFILES/.config/zathura/zathurarc" "$HOME/.config/zathura/zathurarc"
