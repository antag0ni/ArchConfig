#!/bin/bash
set -euo pipefail

PROFILE="$HOME_DIR/.bash_profile"

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