```
   _____                .__    _________                _____.__        
  /  _  \_______   ____ |  |__ \_   ___ \  ____   _____/ ____\__| ____  
 /  /_\  \_  __ \_/ ___\|  |  \/    \  \/ /  _ \ /    \   __\|  |/ ___\ 
/    |    \  | \/\  \___|   Y  \     \___(  <_> )   |  \  |  |  / /_/  >
\____|__  /__|    \___  >___|  /\______  /\____/|___|  /__|  |__\___  / 
        \/            \/     \/        \/            \/        /_____/  
```

Modular Arch Linux post-install scripts for a Hyprland-centered desktop.


## Quick start

1. Copy this repo to your new machine.
2. `chmod +x install.sh modules/*.sh`
3. (Optional) tweak `profiles/default.conf` or create your own profile.
4. `sudo ./install.sh` (or `sudo ./install.sh --profile laptop`)


## Features

- **Modular installer** – every concern lives in `modules/<name>.sh`, making it trivial to add/remove pieces.
- **Profiles** – reusable configs in `profiles/*.conf` define module order plus per-machine environment overrides.
- **Dry run mode** – `--dry-run` prints every command without executing, so you can audit before touching a fresh install.
- **Package groups** – the base module splits packages into logical groups (core, CLI, GPU, GNOME, Wayland, custom) and lets you toggle them via env vars.
- **Shared utilities** – `modules/utils.sh` centralizes logging, dry-run safety, privilege helpers, backups, and config linking.


## Profiles & configuration

Profiles are small Bash snippets sourced before modules run. Because the installer temporarily enables `set -a`, anything you define becomes an exported environment variable for the modules.

What profiles can do:

- Override modules: `MODULES=(base hyprland dotfiles)`
- Adjust base package groups: `export BASE_PACKAGE_GROUPS="core,cli,wayland"`
- Add extra packages: `export BASE_EXTRA_PACKAGES="htop fzf neovim"`
- Skip updates: `export BASE_SKIP_SYSTEM_UPDATE=true`
- Change services: `export BASE_NETWORK_SERVICE="systemd-networkd.service"`

Create new profiles by copying `profiles/default.conf` to `profiles/<name>.conf` and editing the exports. Select them with `./install.sh --profile <name>` or provide an absolute path.


## Usage examples

- Default install (uses `profiles/default.conf` if present):  
  `sudo ./install.sh`
- Safe rehearsal without touching the system:  
  `sudo ./install.sh --dry-run --profile laptop`
- Custom module order overriding the profile:  
  `sudo ./install.sh --profile workstation base hyprland dotfiles`
- Using inline module override flag:  
  `sudo ./install.sh --modules base,dev,hyprland`


## Adding a new module

1. Create `modules/<name>.sh` and start with `#!/usr/bin/env bash` + `set -euo pipefail`.
2. Source `modules/utils.sh` to get logging, package installation, `run_as_root`, `link_config`, etc.
3. Read configuration from environment variables so profiles can enable/disable features.
4. Let the helpers handle `--dry-run` automatically—no need for manual guards.
5. Document the module briefly (either here or in the profile) so others know how to use it.


## Base module package groups

`modules/base.sh` accepts the following group keys via `BASE_PACKAGE_GROUPS` (comma or space separated):

| Key       | Description / packages                                                                 |
|-----------|-----------------------------------------------------------------------------------------|
| `core`    | Essential system tooling (`base-devel`, `sudo`, `git`, `networkmanager`, man pages…)    |
| `cli`     | Terminal apps (`kitty`, `vim`, `nano`, `btop`)                                          |
| `archive` | Archive/compression utilities (`tar`, `zip`, `unzip`)                                   |
| `gpu`     | Microcode + drivers (`intel-ucode`, `xf86-video-intel`, `nvidia`, `nvidia-utils`)       |
| `gnome`   | GNOME desktop meta-package                                                              |
| `wayland` | Wayland plumbing (`wl-clipboard`, `pipewire`, `wireplumber`, `mesa`, etc.)              |
| `custom`  | Whatever you list in `BASE_EXTRA_PACKAGES`                                              |

Example profile snippets:

```bash
# work laptop
MODULES=(base hyprland dev dotfiles)
export BASE_PACKAGE_GROUPS="core,cli,archive,gpu,wayland"

# server
MODULES=(base headless)
export BASE_PACKAGE_GROUPS="core,cli,archive"
export BASE_ENABLE_NETWORK_SERVICE=false
```


## Dotfiles deployment

Store application configs inside `dotfiles/<app>/…` and let the corresponding module sync them into the user’s home directory. Out of the box:

- `modules/hyprland.sh` copies `dotfiles/hyprland/` into `~/.config/hypr` using `rsync`, backing up/overwriting files safely via `deploy_directory`.

Environment overrides (set them in a profile or before running the installer):

| Variable | Default | Description |
|----------|---------|-------------|
| `DOTFILES_DIR` | `<repo>/dotfiles` | Root directory containing subfolders per app |
| `HYPRLAND_DOTFILES_SOURCE` | `$DOTFILES_DIR/hyprland` | Source folder to deploy |
| `HYPRLAND_DOTFILES_DEST` | `$HOME/.config/hypr` | Target directory inside the user’s home |

To add dotfiles for another module, drop them into `dotfiles/<module>/` and call `deploy_directory` from that module with the desired destination.

