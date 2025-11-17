

install_pkgs() {
    if ! command -v pacman >/dev/null 2>&1; then
        echo "pacman not found; cannot install packages: $*" >&2
        return 2
    fi
    run_as_root pacman -S --noconfirm --needed "$@"
}

install_aur() {
    if [[ -z "${USERNAME:-}" ]]; then
        echo "USERNAME not set; cannot install AUR packages" >&2
        return 2
    fi
    run_as_user yay -S --noconfirm --needed "$@"
}

link_config() {
    local src="$1"
    local dest="$2"

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
}

# Logging helpers
info()  { printf "[\033[1;34m*\033[0m] %s\n" "$1"; }
warn()  { printf "[\033[1;33m!\033[0m] %s\n" "$1"; }
err()   { printf "[\033[1;31mX\033[0m] %s\n" "$1"; }

# Check root
is_root() { [[ $(id -u) -eq 0 ]]; }

# Run a command as root (uses sudo if available)
run_as_root() {
    if is_root; then
        "$@"
    else
        if command -v sudo >/dev/null 2>&1; then
            sudo -E "$@"
        else
            err "Not running as root and sudo not found: cannot run $*"
            return 2
        fi
    fi
}

# Run a command as the target user (USERNAME must be set)
run_as_user() {
    local user="${USERNAME:-}"
    if [[ -z "$user" ]]; then
        err "USERNAME not set; cannot run as user"
        return 2
    fi
    if is_root; then
        sudo -u "$user" -H "$@"
    else
        if [[ "$(id -un)" == "$user" ]]; then
            "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo -u "$user" -H "$@"
        else
            err "Cannot run as $user: sudo not available"
            return 2
        fi
    fi
}

# Append a block to a file if a marker string is not present
append_block_if_missing() {
    local file="$1" marker="$2" block="$3"
    if [[ -f "$file" && $(grep -qF "$marker" "$file" 2>/dev/null; echo $?) -eq 0 ]]; then
        return 0
    fi
    mkdir -p "$(dirname "$file")"
    printf '%s' "$block" >> "$file"
}
