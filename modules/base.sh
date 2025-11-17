#!/usr/bin/env bash
set -euo pipefail

# Base module
# Expects: USERNAME and HOME_DIR exported by the caller (install wrapper)

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_file="$script_dir/utils.sh"
if [[ -f "$utils_file" ]]; then
    # shellcheck source=/dev/null
    source "$utils_file"
else
    printf '[X] utils.sh not found at %s\n' "$utils_file" >&2
    exit 2
fi

info "Running BASE module…"

# Package lists (split into logical groups for easier customization)
CORE_SYSTEM_PACKAGES=(
    base-devel
    sudo
    git
    curl
    wget
    rsync
    reflector
    fastfetch
    networkmanager
    xdg-user-dirs
    xdg-utils
    man-db
    man-pages
)

CLI_AND_TERMINAL_PACKAGES=(
    kitty
    vim
    nano
    btop
)

ARCHIVE_UTILS=(
    unzip
    tar
    zip
)

GPU_AND_MICROCODE_PACKAGES=(
    nvidia
    nvidia-utils
    intel-ucode
    xf86-video-intel
)

GNOME_DESKTOP_PACKAGES=(
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

install_group() {
    local label="$1"
    local array_name="$2"
    local -n pkgs_ref="$array_name"

    if [[ ${#pkgs_ref[@]} -eq 0 ]]; then
        warn "No packages defined for $label"
        return
    fi

    info "Installing $label..."
    install_pkgs "${pkgs_ref[@]}"
}

# Update system
info "Updating system..."
run_as_root pacman -Syu --noconfirm

# Install packages (each group can be customized or commented out)
install_group "core system packages" CORE_SYSTEM_PACKAGES
install_group "CLI and terminal packages" CLI_AND_TERMINAL_PACKAGES
install_group "archive utilities" ARCHIVE_UTILS
install_group "GPU and microcode packages" GPU_AND_MICROCODE_PACKAGES
install_group "GNOME desktop packages" GNOME_DESKTOP_PACKAGES
install_group "Wayland essentials" WAYLAND_ESSENTIALS

# Enable essential services
info "Enabling system services..."
run_as_root systemctl enable --now NetworkManager.service || warn "Failed enabling NetworkManager"

# Create XDG user dirs for the target user if xdg-user-dirs-update exists
if command -v xdg-user-dirs-update >/dev/null 2>&1; then
    if [[ -n "${USERNAME:-}" && -n "${HOME_DIR:-}" ]]; then
        info "Creating XDG user directories for $USERNAME"
        run_as_user xdg-user-dirs-update || warn "xdg-user-dirs-update failed for $USERNAME"
    else
        warn "USERNAME or HOME_DIR not set; skipping XDG user dirs creation"
    fi
fi

# AUR helper (yay) installation (uncomment to enable)
# if ! command -v yay &>/dev/null; then
#     info "Installing AUR helper: yay..."
#     if [[ -n "${USERNAME:-}" && -n "${HOME_DIR:-}" ]]; then
#         run_as_user bash -c "
#            cd \"$HOME_DIR\" || exit 1
#            git clone https://aur.archlinux.org/yay.git
#            cd yay || exit 1
#            makepkg -si --noconfirm
#        " || warn "Failed to install yay as $USERNAME"
#    else
#        warn "USERNAME or HOME_DIR not set; cannot install yay"
#    fi
# fi

info "[✓] Base module complete."
