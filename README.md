<p align="center">
  <img src="https://www.debian.org/logos/openlogo-nd.svg" alt="Debian" width="100">
</p>

# Debian Setup Script

![Version](https://img.shields.io/badge/version-0.6.0-blue)
![Platform](https://img.shields.io/badge/platform-Debian%2013-A81D33?logo=debian)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

Post-install automation for the impatient developer.

Interactive CLI tool that automates common Debian post-installation tasks: system configuration, package managers, SSH, developer tools, software installation, and more.

## Features

### System essentials
- **Sudoers** -- Add/remove current user to sudoers
- **Password Feedback** -- Enable/disable asterisks on sudo password prompt
- **Default Editor** -- Configure vim as system editor with `EDITOR`/`SUDO_EDITOR`
- **Zram Swap** -- Install and configure compressed swap in RAM (zstd)
- **Kernel** -- Switch between stable and backports kernel with safe removal and reboot
- **Slimbook EVO** -- Install Slimbook repository and EVO/GNOME meta-packages

### Package managers
- **APT Sources** -- Modernize to DEB822, toggle non-free/backports/deb-src/testing
- **Flatpak** -- Install Flatpak with Flathub repository
- **Nix** -- Install/remove Nix package manager (multi-user daemon, flakes toggle)

### SSH
- **OpenSSH Server** -- Install and manage openssh-server with service control
- **SSH Access** -- Toggle pubkey-only, pubkey+password, or password-only with root login control
- **SSH Keys** -- Generate ED25519 keys with suffix support for multiple identities
- **SSH Config** -- Manage `~/.ssh/config` entries for GitHub, GitLab, and custom servers
- **Commit Signing** -- Configure git commit signing with SSH keys, conditional `includeIf` for multi-identity setups

### Developer tools
- **Build Essentials** -- Core compilation tools and development libraries
- **Node.js** -- fnm + Node.js LTS
- **Python** -- uv package manager
- **Rust** -- rustup/cargo
- **Go** -- Go via APT or official tarball

### Software
- **Utilities** -- CLI utilities (fzf, bat, ripgrep, fd, htop, btop, jq, etc.)
- **Media** -- Media tools and codecs
- **Editors** -- VS Code (with extensions management) and Neovim (LazyVim)
- **Terminals** -- Alacritty (build from source), Kitty (user-space installer), Ptyxis (APT)
- **Browsers** -- Brave, LibreWolf, Mullvad Browser, Chromium

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

Run without options to start the interactive menu. Navigate with arrow keys, confirm with Enter, go back with Escape, exit with Ctrl+C.

## Project structure

```
debian-setup/
├── debian-setup                    # Entry point
├── VERSION
├── src/
│   ├── lib/
│   │   ├── colors.sh              # Catppuccin Mocha palette
│   │   ├── gum.sh                 # Gum wrappers (choose, input, SIGINT)
│   │   ├── log.sh                 # Logging (terminal + file)
│   │   ├── apt.sh                 # APT package list utilities
│   │   ├── system.sh              # System info queries
│   │   ├── ui.sh                  # UI components
│   │   └── xdg.sh                 # XDG Base Directory support
│   ├── modules/
│   │   ├── health.sh
│   │   ├── system/
│   │   │   ├── main.sh            # Sudoers, Password Feedback, Editor,
│   │   │   ├── ...                # Zram, Kernel, Slimbook
│   │   ├── packages/
│   │   │   ├── main.sh            # APT Sources, Flatpak, Nix
│   │   │   ├── ...
│   │   ├── ssh/
│   │   │   ├── main.sh            # Server, Access, Keys, Config, Signing
│   │   │   ├── ...
│   │   ├── devtools/
│   │   │   ├── main.sh            # Build, Node, Python, Rust, Go
│   │   │   ├── ...
│   │   ├── software/
│   │   │   ├── main.sh            # Utilities, Media, Editors, Terminals,
│   │   │   ├── ...                # Browsers
│   │   └── settings/
│   │       ├── main.sh
│   │       └── logs.sh
│   └── menu.sh
├── packages/
│   ├── apt/                        # Package lists (build, utils, media)
│   └── vscode/
│       └── extensions.txt          # VS Code extensions (id|label)
```

## Design

- **Catppuccin Mocha** color palette throughout
- **XDG compliant** -- logs stored in `$XDG_STATE_HOME/debian-setup/logs/`
- **Session logging** -- all actions recorded to daily log files
- **Wizard pattern** -- each task shows current status and offers contextual actions (install/remove, enable/disable)
- **Non-destructive** -- every configuration change can be undone from the same menu
- **Repo cleanup** -- removing browsers/packages with external repos also removes the repo and GPG key
- **Ctrl+C safe** -- clean exit from any prompt via SIGINT handling
