#!/usr/bin/env bash
set -euo pipefail

# Minimal, safer installer wrapper for modular scripts in `modules/`

script_name="$(basename "$0")"

info() { printf "[\033[1;34m*\033[0m] %s\n" "$1"; }
warn() { printf "[\033[1;33m!\033[0m] %s\n" "$1"; }
err()  { printf "[\033[1;31mX\033[0m] %s\n" "$1"; }

usage() {
    cat <<EOF
Usage: $script_name [options] [module...]

Options:
  --help        Show this help
  --list        List available modules
  --dry-run     Print actions without executing modules
  --modules A,B Override enabled modules (comma-separated)
  --profile P   Load profile (name or path) from profiles/

If modules are provided as positional arguments, those modules are run in order.
Otherwise the default set in the script is used.
EOF
    exit 0
}

on_error() {
    local rc=$?
    err "Error on or near line ${1:-unknown} (exit code $rc)"
    exit $rc
}
trap 'on_error $LINENO' ERR

# Auto-detect username safely
if [[ -n "${SUDO_USER:-}" ]]; then
    USERNAME="$SUDO_USER"
else
    USERNAME="$(whoami)"
fi

# Determine home directory from system database when possible
HOME_DIR="$(getent passwd "$USERNAME" | cut -d: -f6 || true)"
if [[ -z "$HOME_DIR" ]]; then
    HOME_DIR="/home/$USERNAME"
fi

MODULES=(base hyprland)

DRY_RUN=false
PROFILE_SPEC=""
PROFILE_DIR="profiles"

# parse args (simple)
POSITIONAL=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h)
            usage
            ;;
        --list)
            echo "Available modules:"
            for m in modules/*.sh; do
                [[ -f "$m" ]] || continue
                echo " - $(basename "$m" .sh)"
            done
            exit 0
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --modules)
            shift
            IFS=',' read -r -a MODULES <<< "$1"
            shift
            ;;
        --modules=*)
            IFS=',' read -r -a MODULES <<< "${1#*=}"
            shift
            ;;
        --profile)
            shift
            PROFILE_SPEC="${1:-}"
            shift
            ;;
        --profile=*)
            PROFILE_SPEC="${1#*=}"
            shift
            ;;
        --)
            shift
            break
            ;;
        -*|--*)
            warn "Unknown option $1"
            usage
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

if [[ ${#POSITIONAL[@]} -gt 0 ]]; then
    MODULES=("${POSITIONAL[@]}")
fi

resolve_profile_path() {
    local spec="$1"
    local default_path="$PROFILE_DIR/default.conf"

    if [[ -z "$spec" ]]; then
        [[ -f "$default_path" ]] && printf '%s\n' "$default_path" && return 0
        return 1
    fi

    if [[ -f "$spec" ]]; then
        printf '%s\n' "$spec"
        return 0
    fi

    local candidate="$PROFILE_DIR/${spec}.conf"
    if [[ -f "$candidate" ]]; then
        printf '%s\n' "$candidate"
        return 0
    fi

    return 1
}

if profile_path="$(resolve_profile_path "$PROFILE_SPEC")"; then
    info "Loading profile from $profile_path"
    set -a
    # shellcheck disable=SC1090
    if ! source "$profile_path"; then
        set +a
        err "Failed to load profile $profile_path"
        exit 2
    fi
    set +a
else
    if [[ -n "$PROFILE_SPEC" ]]; then
        warn "Profile '$PROFILE_SPEC' not found; continuing with inline defaults"
    fi
fi

info "Arch Post-Install Script"
info "User: $USERNAME"
info "Home: $HOME_DIR"
info "Modules enabled: ${MODULES[*]}"

export DRY_RUN

if [[ ! -d "modules" ]]; then
    err "modules/ directory not found"
    exit 2
fi

run_module() {
    local module_name="$1"
    local module_path="modules/${module_name}.sh"

    if [[ ! -f "$module_path" ]]; then
        warn "Module '$module_name' not found"
        return 1
    fi

    info "Running module: $module_name"

    if [[ "$DRY_RUN" == true ]]; then
        echo "DRY-RUN: would source $module_path with USERNAME=$USERNAME HOME_DIR=$HOME_DIR"
        return 0
    fi

    # Run each module in a subshell to avoid leaking variables and allow set -e in modules
    ( export USERNAME HOME_DIR DRY_RUN; source "$module_path" )
}

for module in "${MODULES[@]}"; do
    run_module "$module" || warn "Module $module exited with non-zero status"
done

info "\n[✓] Installation complete."
