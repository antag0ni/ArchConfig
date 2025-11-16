# Auto-detect username safely
if [[ -n "${SUDO_USER:-}" ]]; then
    USERNAME="$SUDO_USER"
else
    USERNAME="$(whoami)"
fi

HOME_DIR="/home/$USERNAME"

INSTALL_DOTFILES=true   # false = skip linking configs
AUR_HELPER="yay"        # or paru
DOTFILES_DIR="$(pwd)/dotfiles"
