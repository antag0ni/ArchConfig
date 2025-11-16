#!/bin/bash

echo "[*] Running BASE module…"

# ---------------------------
# Package lists
# ---------------------------
BASE_PACKAGES=(
    base-devel
    kitty
    sudo
    vim
    nano
    git
    curl
    wget
    unzip
    tar
    zip
    btop
    rsync
    reflector
    fastfetch
    networkmanager
    xdg-user-dirs
    xdg-utils
    man-db
    man-pages
    nvidia
    nvidia-utils
    intel-ucode
    xf86-video-intel
    gnome
)

WAYLAND_ESSENTIALS=(
    wl-clipboard
    seatd
    egl-wayland
    polkit
    pipewire
    pipewire-pulse
    wireplumber
    mesa
)

# ---------------------------
# Mirror optimization
# ---------------------------
#echo "[*] Optimizing mirrors…"
#reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist

# ---------------------------
# System update
# ---------------------------
echo "[*] Updating system..."
pacman -Syu --noconfirm

# ---------------------------
# Pacman essential packages
# ---------------------------
echo "[*] Installing essential system packages…"
sudo pacman -S --noconfirm --needed "${BASE_PACKAGES[@]}"
sudo pacman -S --noconfirm --needed "${WAYLAND_ESSENTIALS[@]}"

# ---------------------------
# Enable essential services
# ---------------------------
echo "[*] Enabling system services…"

systemctl enable --now NetworkManager
#systemctl enable --now seatd.service

# ---------------------------
# Create user directories
# ---------------------------
#echo "[*] Creating XDG user directories…"
#sudo -u "$USERNAME" xdg-user-dirs-update

# ---------------------------
# AUR Helper (yay)
# ---------------------------
# if ! command -v yay &>/dev/null; then
#     echo "[*] Installing AUR helper: yay…"
#     sudo -u "$USERNAME" bash <<'EOF'
# cd "$HOME_DIR"
# git clone https://aur.archlinux.org/yay.git
# cd yay
# makepkg -si --noconfirm
# EOF
# fi

echo "[✓] Base module complete."
