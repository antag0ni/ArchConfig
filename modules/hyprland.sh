#!/bin/bash
set -euo pipefail

# Detect real user (not root)
if [[ -n "${SUDO_USER:-}" ]]; then
    REAL_USER="$SUDO_USER"
else
    REAL_USER="$(whoami)"
fi

USER_HOME=$(eval echo "~$REAL_USER")

# -----------------------------
# Install packages
# -----------------------------
sudo pacman -S --noconfirm --needed hyprland uwsm xdg-desktop-portal-hyprland hyprpolkitagent

# -----------------------------
# Update .bash_profile
# -----------------------------
PROFILE="$HOME/.bash_profile"

# Add the block only if it's not already in the file
if ! grep -q "uwsm check may-start" "$PROFILE"; then
cat << 'EOF' >> "$PROFILE"

# UWSM_AUTOSTART
if uwsm check may-start; then
    exec uwsm start hyprland.desktop
fi

EOF
    echo "Added UWSM autostart block to $PROFILE"
else
    echo "UWSM autostart block already exists in $PROFILE"
fi  