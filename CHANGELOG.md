# Changelog

All notable changes to this project will be documented in this file.

## [0.12.5] - 2026-02-10

### Added

- **GRUB module** under System Essentials -- configure boot resolution (GRUB_GFXMODE with presets and custom input), remove background image, restore defaults
- **Plymouth theme selection** -- choose between `spinner` (generic animation) and `bgrt` (UEFI manufacturer logo) in Plymouth wizard

## [0.12.4] - 2026-02-09

### Fixed

- Remove spinner from `--search` mode (instant load caused visual glitch)

## [0.12.3] - 2026-02-09

### Fixed

- Header repaint after health check output scrolls past visible area

## [0.12.2] - 2026-02-09

### Added

- Loading spinner while collecting task data in search modes (`-s`, `-si`, `-sr`)

## [0.12.1] - 2026-02-09

### Fixed

- Plymouth theme detection now reads config file as fallback when `plymouth-set-default-theme` is not in user PATH

## [0.12.0] - 2026-02-09

### Added

- **Global search mode** (`--search` / `-s`) -- flat filterable list of all available options across all modules
- **Search filters** -- `--search-to-install` / `-si` shows only non-installed options, `--search-to-remove` / `-sr` shows only installed options, with dynamic counters in the header
- **System Upgrade** now lists individual upgradable package names

## [0.11.7] - 2026-02-09

### Fixed

- LibreOffice detection now checks `libreoffice-common` instead of metapackage (detects default Debian 13 install)

## [0.11.6] - 2026-02-09

### Fixed

- Desktop database refresh after install/remove in Balena Etcher and Kitty for GNOME Activities

## [0.11.5] - 2026-02-09

### Changed

- Balena Etcher switched from .deb to zip binary install (fixes broken dependency on Debian 13)
  - Downloads linux-x64 zip from GitHub releases, installs to `~/.local/share/balena-etcher/`
  - Creates `.desktop` entry and downloads icon for GNOME Activities

## [0.11.4] - 2026-02-09

### Fixed

- Balena Etcher download URL resolved dynamically from GitHub API (fixed 404)

## [0.11.3] - 2026-02-09

### Fixed

- Flatpak install/remove and remote operations now use sudo for system-wide access (13 modules)

## [0.11.2] - 2026-02-09

### Added

- **Balena Etcher module** under Software > Productivity -- USB/SD card flasher (deb from GitHub releases)

## [0.11.1] - 2026-02-09

### Added

- **LocalSend module** under Software > Productivity -- local network file sharing (Flatpak)

## [0.11.0] - 2026-02-09

### Added

- **Browser Themes** info module under UI -- Catppuccin Mocha install guide for Brave, Chromium, Firefox and LibreWolf

### Changed

- Renamed GNOME module to **UI** in main menu, health checks and breadcrumbs

## [0.10.9] - 2026-02-09

### Fixed

- System Upgrade module: upgradable count produced double output when zero packages available

## [0.10.8] - 2026-02-09

### Added

- **System Upgrade module** under Package Managers -- apt-get update, dist-upgrade and autoremove with upgradable package count
- **Homebrew module** under Package Managers -- install, update and remove Homebrew on Linux with automatic dependency setup

## [0.10.7] - 2026-02-09

### Fixed

- Gum auto-installer now uses `su -c` (root password) when user has no sudo access on fresh installs

## [0.10.6] - 2026-02-09

### Added

- **Dotfiles module** under Shell -- clone and apply dotfiles via GNU Stow
  - Clone repo to `~/.dotfiles`, apply/remove individual packages
  - Built-in help with repo structure guide and Stow usage tips
  - Portable: dotfiles repo works independently on any system with `stow`

## [0.10.5] - 2026-02-09

### Added

- **Plymouth module** under System Essentials -- boot splash with spinner theme, GRUB splash parameter, initramfs update
- **Hibernate module** under System Essentials -- swap file creation (priority 1, coexists with zram), GRUB resume, initramfs resume, systemd-sleep suspend-then-hibernate, logind lid switch

## [0.10.4] - 2026-02-09

### Fixed

- Flatpak install/remove results now pause for user confirmation instead of being cleared instantly (11 modules)
- Install instructions updated for fresh Debian without sudo (`su -c` instead of `sudo`)

### Changed

- Removed backports kernel installation from Slimbook EVO module (handled separately via Kernel module)

## [0.10.3] - 2026-02-08

### Added

- **Fonts sub-module** under Software -- Nerd Fonts management with individual install/remove
  - Noto, Symbols Only, Hack, CaskaydiaCove, FiraCode
  - Downloads from GitHub releases as `.tar.xz`, installs to `~/.local/share/fonts/`
  - Wizard pattern with show, install all, select install, remove, edit list

## [0.10.2] - 2026-02-08

### Fixed

- Entry point now resolves symlinks for `SCRIPT_DIR` (fixes `VERSION: No such file` when invoked via `~/.local/bin/debian-setup`)

## [0.10.1] - 2026-02-08

### Added

- **Installer script** (`install.sh`) -- one-line install via `curl | bash`
  - Clones repo to `$XDG_DATA_HOME/debian-setup`, symlinks to `~/.local/bin`
  - HTTPS clone with SSH fallback
  - Ensures `~/.local/bin` is in PATH (`.bashrc` with marker comment)
- `--update` flag -- pull latest version with `git pull --ff-only`
- `--uninstall` flag -- remove repo, symlink, PATH entry, and optionally logs

## [0.10.0] - 2026-02-08

### Added

- **Development module** -- restructured from "Developer tools" into three subcategories:
  - **Environments** -- Node.js, Python, Rust, Go
  - **Tools** -- Build Essentials, GitHub CLI, AWS CLI, Docker, HTTPie, MongoDB Compass
  - **AI** -- Claude Code, OpenCode, GitHub Copilot CLI, AI Resources
- **Virtualization module** -- QEMU/KVM with virt-manager, user groups, libvirtd service, and default network management
- **Hardware module** -- top-level module for hardware-specific tasks (Slimbook EVO)
- Inotify watchers module with RAM detection, multiple instances support, and custom input
- Docker module with post-install group management and three-state detection (not in group / restart needed / active)
- yq added to CLI utilities package list

### Changed

- Settings renamed to **Diagnostics**
- Slimbook EVO moved from System to Hardware module
- Main menu now shows: System Essentials, Package Managers, OpenSSH Server, Development, Shell, Hardware, Virtualization, Software, GNOME, Diagnostics

### Fixed

- Persistent header recovery after terminal scroll (dirty flag approach)
- Docker installer no longer blocks on sudo (removed pipe + `</dev/tty` conflict)

## [0.9.1] - 2026-02-08

### Added

- Standalone dependencies wizard for Neovim module
- CLAUDE.md with project conventions and architecture documentation

### Changed

- GNOME extensions module rewritten with VS Code wizard pattern
- Normalized gum::choose for menus with fewer than 5 items
- Deduplicated apt::read_deb_list by delegating to apt::read_list
- Renamed gnome_icons/gnome_cursors to icons/cursors namespace

### Fixed

- Critical bugs found in code review (multiple fixes)
- Protected gsettings/dconf commands and sudo apt-get against set -e
- Missing `</dev/tty` on first sudo after ui::flush_input in Nix module
- Guarded apt modernize-sources against failure with set -e
- Validated user input in SSH config to prevent sed/grep injection
- Replaced wget with curl in Element GPG key download
- Escaped dots in shell version for regex in extensions API parsing
- Used while-read instead of for loop on command substitution
- Used absolute /root path instead of ~root tilde in Nix removal
- Separated zram enable and restart into independent operations
- Used trap RETURN for tmpfile cleanup in Slimbook repo setup
- Added error handling to pipe+tee APT sources write operations
- Added missing "Edit packages list" option to apt::deb_wizard
- Removed unused log::section_break function

## [0.9.0] - 2026-02-07

### Added

- **GNOME module** with four sub-modules:
  - **Appearance** -- GTK theme (Catppuccin Mocha with accent colors), icons (Papirus), cursors (Catppuccin), terminal profile
  - **Keyboard** -- English intl layout, 4 fixed workspaces, custom keybindings
  - **Terminal CSS** -- VTE terminal padding for GTK3 and GTK4
  - **Extensions** -- Blur My Shell, Vitals, AppIndicator, Privacy Quick Settings, Quick Settings Audio Panel, User Themes
- Nextcloud Desktop with Nautilus integration added to Productivity

## [0.8.1] - 2026-02-07

### Added

- **Productivity sub-module** -- GIMP, Inkscape, OnlyOffice (Flatpak), LibreOffice (APT)

## [0.8.0] - 2026-02-07

### Added

- **Messaging sub-module** -- Telegram (Flatpak), Slack (Flatpak), Discord (Flatpak), Element (APT repo)

## [0.7.0] - 2026-02-07

### Added

- **Security sub-module** with five categories:
  - **VPN** -- Mullvad VPN, Proton VPN
  - **Password Managers** -- Proton Pass, Proton Pass CLI, KeePassXC, Bitwarden CLI
  - **Authenticators** -- Proton Authenticator, Yubico Authenticator
  - **Hardware Keys** -- YubiKey Manager, Nitrokey App2
  - **OpenPGP** -- gnupg, seahorse, scdaemon, pinentry-gnome3
- gum::filter wrapper for filterable menu lists

### Fixed

- Preserved Mullvad repo when VPN is still installed on browser removal

## [0.6.2] - 2026-02-07

### Fixed

- Added Developer tools and Software to health check

## [0.6.0] - 2026-02-07

### Added

- **Browsers sub-module** -- Brave, LibreWolf, Mullvad Browser, Chromium

### Changed

- Renamed System core to System essentials
- Title Case for all menu labels
- Compact package list display in APT wizards
- Cached VS Code extensions list with compact display
- Removed status checks from module menus for faster navigation

### Fixed

- Nix flakes daemon restart and cleanup on remove
- Restored tput-based content clearing

## [0.5.0] - 2026-02-07

### Added

- **Developer tools module** -- Build essentials, Node.js (fnm), Python (uv), Rust (rustup), Go
- **Software module** with four sub-modules:
  - **Utilities** -- CLI utilities (fzf, bat, ripgrep, fd, htop, btop, jq, etc.)
  - **Media** -- Media tools and codecs
  - **Editors** -- VS Code (with extensions management), Neovim
  - **Terminals** -- Alacritty (build from source), Kitty (user-space installer), Ptyxis (APT)
- APT package list library for declarative package management
- Kernel management task (stable/backports switch with safe removal)
- Slimbook EVO setup task
- Nix flakes toggle
- GNOME Software Flatpak plugin

### Changed

- Renamed SSH to OpenSSH server in main menu

## [0.3.0] - 2026-02-07

### Added

- **SSH module** with five tasks:
  - SSH server configuration
  - SSH access mode (pubkey-only, pubkey+password, password-only)
  - SSH key generation (ED25519 with suffix support)
  - SSH config management (GitHub, GitLab, custom servers)
  - Git commit signing with SSH keys
- Ctrl+C handling in gum wrappers (SIGINT propagation)

## [0.2.0] - 2026-02-06

### Added

- Initial release with core infrastructure:
  - Catppuccin Mocha color palette
  - XDG-compliant logging system
  - Gum dependency check and wrappers
  - Persistent UI header with version display
  - Health check module
  - Session log management
- **System module** -- Sudoers, password feedback, default editor, zram swap
- **Package managers** -- APT sources (DEB822), Flatpak, Nix
- Interactive wizard pattern with dynamic menu options
- Escape key as Back navigation in all menus
