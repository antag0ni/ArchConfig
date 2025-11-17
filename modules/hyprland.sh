#!/usr/bin/env bash
set -euo pipefail

# Hyprland module
# Expects: USERNAME and HOME_DIR exported by the caller

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
utils_file="$script_dir/utils.sh"
if [[ -f "$utils_file" ]]; then
    # shellcheck source=/dev/null
    source "$utils_file"
else
    printf '[X] utils.sh not found at %s\n' "$utils_file" >&2
    exit 2
fi

PROFILE="${HOME_DIR:-$HOME}/.bash_profile"

PACKAGES=(
    hyprland
    uwsm
    xdg-desktop-portal-hyprland
    hyprpolkitagent
)

info "Installing Hyprland packages: ${PACKAGES[*]}"
install_pkgs "${PACKAGES[@]}"

# Add the autostart block only if it's not already in the file
if ! run_as_user grep -qF "UWSM_AUTOSTART" "$PROFILE" 2>/dev/null; then
    info "Adding UWSM autostart block to $PROFILE"
    block=$'# UWSM_AUTOSTART\nif uwsm check may-start; then\n    exec uwsm start hyprland.desktop\nfi\n'

    if run_as_user bash -c "mkdir -p \"\$(dirname \"$PROFILE\")\" && printf '%s' \"$block\" >> \"$PROFILE\""; then
        info "Added UWSM autostart block to $PROFILE"
    else
        warn "Could not append autostart block to $PROFILE (permission denied)"
    fi
else
    info "UWSM autostart block already exists in $PROFILE"
fi

# Deploy Hyprland dotfiles if present
repo_root="$(cd "$script_dir/.." && pwd)"
dotfiles_root="${DOTFILES_DIR:-$repo_root/dotfiles}"
hyprland_dotfiles="${HYPRLAND_DOTFILES_SOURCE:-$dotfiles_root/hyprland}"
hyprland_target="${HYPRLAND_DOTFILES_DEST:-${HOME_DIR:-$HOME}/.config/hypr}"

if [[ -d "$hyprland_dotfiles" ]]; then
    info "Deploying Hyprland dotfiles -> $hyprland_target"
    if deploy_directory "$hyprland_dotfiles" "$hyprland_target"; then
        info "Hyprland dotfiles deployed"
    else
        warn "Failed to deploy Hyprland dotfiles"
    fi
else
    warn "Hyprland dotfiles not found at $hyprland_dotfiles; skipping"
fi