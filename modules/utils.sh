run_module() {
    local module_name="$1"
    local module_path="modules/${module_name}.sh"

    if [[ -f "$module_path" ]]; then
        echo "[*] Running module: $module_name"
        source "$module_path"
    else
        echo "[!] Module '$module_name' not found"
    fi
}

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
