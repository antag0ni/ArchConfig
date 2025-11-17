#!/usr/bin/env bash
set -euo pipefail

: "${DRY_RUN:=false}"

# Logging helpers
info()  { printf "[\033[1;34m*\033[0m] %s\n" "$1"; }
warn()  { printf "[\033[1;33m!\033[0m] %s\n" "$1"; }
err()   { printf "[\033[1;31mX\033[0m] %s\n" "$1"; }

print_cmd() {
    local quoted=()
    for arg in "$@"; do
        quoted+=("$(printf "%q" "$arg")")
    done
    printf '%s' "${quoted[*]}"
}

dry_run_notice() {
    info "DRY-RUN: $(print_cmd "$@")"
}

need_cmd() {
    local cmd="$1"
    if ! command -v "$cmd" >/dev/null 2>&1; then
        err "Required command not found: $cmd"
        return 127
    fi
}

install_pkgs() {
    if ! need_cmd pacman; then
        err "pacman not available; cannot install packages: $*"
        return 2
    fi
    run_as_root pacman -S --noconfirm --needed "$@"
}

install_aur() {
    if [[ -z "${USERNAME:-}" ]]; then
        err "USERNAME not set; cannot install AUR packages"
        return 2
    fi
    if ! need_cmd yay; then
        warn "yay not found; skipping AUR packages: $*"
        return 0
    fi
    run_as_user yay -S --noconfirm --needed "$@"
}

link_config() {
    local src="$1"
    local dest="$2"

    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice ln -sf "$src" "$dest"
        return 0
    fi

    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
}

backup_file() {
    local target="$1"
    if [[ ! -e "$target" ]]; then
        return 0
    fi
    local ts suffix backup_path
    ts="$(date +%Y%m%d%H%M%S)"
    suffix="${2:-bak}"
    backup_path="${target}.${suffix}.${ts}"

    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice cp -a "$target" "$backup_path"
        return 0
    fi

    cp -a "$target" "$backup_path"
    info "Backed up $target -> $backup_path"
}

# Check root
is_root() { [[ $(id -u) -eq 0 ]]; }

run_as_root() {
    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice sudo -E "$@"
        return 0
    fi

    if is_root; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -E "$@"
    else
        err "Not running as root and sudo not found: cannot run $*"
        return 2
    fi
}

run_as_user() {
    local user="${USERNAME:-}"
    if [[ -z "$user" ]]; then
        err "USERNAME not set; cannot run as user"
        return 2
    fi

    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice sudo -u "$user" -H "$@"
        return 0
    fi

    if is_root; then
        sudo -u "$user" -H "$@"
    elif [[ "$(id -un)" == "$user" ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo -u "$user" -H "$@"
    else
        err "Cannot run as $user: sudo not available"
        return 2
    fi
}

ensure_group() {
    local group="$1"
    local user="${2:-${USERNAME:-}}"
    if [[ -z "$group" || -z "$user" ]]; then
        warn "ensure_group requires group and user"
        return 1
    fi

    run_as_root groupadd -f "$group"
    if id -nG "$user" | tr ' ' '\n' | grep -Fxq "$group"; then
        return 0
    fi
    run_as_root usermod -aG "$group" "$user"
    info "Added $user to group $group"
}

append_block_if_missing() {
    local file="$1" marker="$2" block="$3"
    if [[ -f "$file" ]] && grep -qF "$marker" "$file" 2>/dev/null; then
        return 0
    fi
    mkdir -p "$(dirname "$file")"
    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice "append block with marker ${marker} into ${file}"
        return 0
    fi
    printf '%s' "$block" >> "$file"
}

deploy_directory() {
    local src="$1"
    local dest="$2"

    if [[ ! -d "$src" ]]; then
        warn "deploy_directory: source '$src' does not exist; skipping"
        return 1
    fi

    if [[ "${DRY_RUN}" == true ]]; then
        dry_run_notice "rsync -a --delete $src/ -> $dest/"
        return 0
    fi

    if ! need_cmd rsync; then
        err "rsync is required to deploy dotfiles"
        return 2
    fi

    run_as_user bash -c '
        set -euo pipefail
        src="$1"
        dest="$2"
        mkdir -p "$dest"
        rsync -a --delete "$src"/ "$dest"/
    ' bash "$src" "$dest"
}
