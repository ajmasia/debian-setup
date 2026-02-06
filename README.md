# debian-setup

![Version](https://img.shields.io/badge/version-0.2.0-blue)
![Platform](https://img.shields.io/badge/platform-Debian%2013-A81D33?logo=debian)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

Post-install automation for the impatient developer.

Interactive CLI tool that automates common Debian post-installation tasks: system configuration, package manager setup, and source management.

## Features

### System core
- **Sudoers** -- Add/remove current user to sudoers
- **Password feedback** -- Enable/disable asterisks on sudo password prompt
- **Default editor** -- Configure vim as system editor with `EDITOR`/`SUDO_EDITOR`
- **Zram swap** -- Install and configure compressed swap in RAM (zstd)

### Package managers
- **APT sources** -- Modernize to DEB822, toggle non-free/backports/deb-src/testing
- **Flatpak** -- Install Flatpak with Flathub repository
- **Nix** -- Install/remove Nix package manager (multi-user daemon)

### Settings
- **Health check** -- System info, dependency status, and task overview
- **Log management** -- View, delete, and clean session logs

## Requirements

- Debian 13 (Trixie) or compatible
- [gum](https://github.com/charmbracelet/gum) -- auto-installed on first run if missing

## Install

```bash
git clone ssh://git.qwertee.link:2022/ajmasia.dev/debian-setup.git
cd debian-setup
chmod +x debian-setup
./debian-setup
```

## Usage

```
debian-setup [options]

Options:
  -v, --version    Show version
  -h, --help       Show this help message
```

Run without options to start the interactive menu. Navigate with arrow keys, confirm with Enter, go back with Escape.

## Project structure

```
debian-setup/
├── debian-setup                    # Entry point
├── VERSION
├── src/
│   ├── lib/
│   │   ├── colors.sh              # Catppuccin Mocha palette
│   │   ├── gum.sh                 # Gum wrappers
│   │   ├── log.sh                 # Logging (terminal + file)
│   │   ├── system.sh              # System info queries
│   │   ├── ui.sh                  # UI components
│   │   └── xdg.sh                 # XDG Base Directory support
│   ├── modules/
│   │   ├── health.sh
│   │   ├── system/
│   │   │   ├── main.sh
│   │   │   ├── sudoers.sh
│   │   │   ├── pwfeedback.sh
│   │   │   ├── editor.sh
│   │   │   └── zram.sh
│   │   ├── packages/
│   │   │   ├── main.sh
│   │   │   ├── apt.sh
│   │   │   ├── flatpak.sh
│   │   │   └── nix.sh
│   │   └── settings/
│   │       ├── main.sh
│   │       └── logs.sh
│   └── menu.sh
```

## Design

- **Catppuccin Mocha** color palette throughout
- **XDG compliant** -- logs stored in `$XDG_STATE_HOME/debian-setup/logs/`
- **Session logging** -- all actions recorded to daily log files
- **Wizard pattern** -- each task shows current status and offers contextual actions (install/remove, enable/disable, edit/configure)
- **Non-destructive** -- every configuration change can be undone from the same menu
