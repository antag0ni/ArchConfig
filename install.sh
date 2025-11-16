#!/usr/bin/env bash
set -euo pipefail

# Available modules
MODULES=(
    base
    hyprland
)

echo "[*] Arch Post-Install Script"
echo "[*] Modules enabled: ${MODULES[*]}"

for module in "${MODULES[@]}"; do
    module_name="$module"
    module_path="modules/${module_name}.sh"

    if [[ -f "$module_path" ]]; then
        echo "[*] Running module: $module_name"
        source "$module_path"
    else
        echo "[!] Module '$module_name' not found"
    fi 
done

echo -e "\n[✓] Installation complete."
