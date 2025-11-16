

install_pkgs() {
    sudo pacman -S --noconfirm --needed "$@"
}

install_aur() {
    sudo -u "$USERNAME" yay -S --noconfirm --needed "$@"
}

link_config() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
}
