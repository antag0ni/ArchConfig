#!/bin/bash

install_pkgs hyprland xdg-desktop-portal-hyprland \
             wayland wl-clipboard grim slurp swaybg brightnessctl

if [[ "$INSTALL_DOTFILES" == true ]]; then
    link_config "$DOTFILES_DIR/hypr" "/home/$USERNAME/.config/hypr"
fi
