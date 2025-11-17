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

CUSTOM_PACKAGES=()
if [[ -n "${BASE_EXTRA_PACKAGES:-}" ]]; then
    read -r -a CUSTOM_PACKAGES <<< "${BASE_EXTRA_PACKAGES//,/ }"
fi

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
if [[ "${BASE_SKIP_SYSTEM_UPDATE:-false}" == true ]]; then
    warn "Skipping system update (BASE_SKIP_SYSTEM_UPDATE=true)"
else
    info "Updating system..."
    run_as_root pacman -Syu --noconfirm
fi

DEFAULT_GROUP_ORDER=("core" "cli" "archive" "gpu" "gnome" "wayland" "custom")
group_list="${BASE_PACKAGE_GROUPS:-${DEFAULT_GROUP_ORDER[*]}}"
group_list="${group_list//,/ }"
if ! read -r -a ENABLED_GROUPS <<< "$group_list"; then
    ENABLED_GROUPS=()
fi

install_group_by_key() {
    local key="$1"
    case "$key" in
        core) install_group "core system packages" CORE_SYSTEM_PACKAGES ;;
        cli) install_group "CLI and terminal packages" CLI_AND_TERMINAL_PACKAGES ;;
        archive) install_group "archive utilities" ARCHIVE_UTILS ;;
        gpu) install_group "GPU and microcode packages" GPU_AND_MICROCODE_PACKAGES ;;
        gnome) install_group "GNOME desktop packages" GNOME_DESKTOP_PACKAGES ;;
        wayland) install_group "Wayland essentials" WAYLAND_ESSENTIALS ;;
        custom) install_group "custom packages" CUSTOM_PACKAGES ;;
        *)
            warn "Unknown package group '$key' requested; skipping"
            ;;
    esac
}

if [[ ${#ENABLED_GROUPS[@]} -eq 0 ]]; then
    warn "BASE_PACKAGE_GROUPS resulted in no package groups; nothing to install"
else
    for group in "${ENABLED_GROUPS[@]}"; do
        install_group_by_key "$group"
    done
fi

# Enable essential services
NETWORK_SERVICE="${BASE_NETWORK_SERVICE:-NetworkManager.service}"
if [[ "${BASE_ENABLE_NETWORK_SERVICE:-true}" == true ]]; then
    info "Enabling system service: $NETWORK_SERVICE"
    run_as_root systemctl enable --now "$NETWORK_SERVICE" || warn "Failed enabling $NETWORK_SERVICE"
else
    warn "Skipping network service enable (BASE_ENABLE_NETWORK_SERVICE=false)"
fi

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
