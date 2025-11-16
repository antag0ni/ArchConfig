#!/usr/bin/env bash
set -euo pipefail

source config.sh

# Load utils
source modules/utils.sh

# Available modules
MODULES=(
    base
    hyprland
)

echo "[*] Arch Post-Install Script"
echo "[*] Modules enabled: ${MODULES[*]}"

for module in "${MODULES[@]}"; do
    run_module "$module"
done

echo -e "\n[✓] Installation complete."
