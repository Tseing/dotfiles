#!/usr/bin/env bash
set -e

DOTFILES="$HOME/dotfiles"

link_path() {
  local source="$1"
  local target="$2"
  local backup

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    rm -f "$target"
  elif [ -e "$target" ]; then
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
}

mkdir -p \
  "$HOME/.config" \
  "$HOME/.config/enchant" \
  "$HOME/.config/zathura" \
  "$HOME/.config/fcitx5/conf" \
  "$HOME/.local/share/fcitx5/themes"

link_path "$DOTFILES/.emacs.d" "$HOME/.emacs.d"
link_path "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
link_path "$DOTFILES/.config/enchant/personal.dic" "$HOME/.config/enchant/en_US.dic"
link_path "$DOTFILES/.config/zathura/zathurarc" "$HOME/.config/zathura/zathurarc"
link_path "$DOTFILES/.config/fcitx5/config" "$HOME/.config/fcitx5/config"
link_path "$DOTFILES/.config/fcitx5/profile" "$HOME/.config/fcitx5/profile"
link_path "$DOTFILES/.config/fcitx5/conf" "$HOME/.config/fcitx5/conf"
link_path "$DOTFILES/.local/share/fcitx5/rime" "$HOME/.local/share/fcitx5/rime"
link_path "$DOTFILES/.local/share/fcitx5/themes/leonis-light" "$HOME/.local/share/fcitx5/themes/leonis-light"
