<p align="center">
  <img src="https://www.debian.org/logos/openlogo-nd.svg" alt="Debian" width="100">
</p>

# Debian Setup Script

![Version](https://img.shields.io/badge/version-0.11.5-blue)
![Platform](https://img.shields.io/badge/platform-Debian%2013-A81D33?logo=debian)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

Post-install automation for the impatient developer.

Interactive CLI tool that automates common Debian post-installation tasks: system configuration, package managers, SSH, development environments, virtualization, software installation, and more.

## Features

### System essentials
- **Sudoers** -- Add/remove current user to sudoers
- **Password Feedback** -- Enable/disable asterisks on sudo password prompt
- **Default Editor** -- Configure vim as system editor with `EDITOR`/`SUDO_EDITOR`
- **Zram Swap** -- Install and configure compressed swap in RAM (zstd)
- **Kernel** -- Switch between stable and backports kernel with safe removal and reboot
- **Inotify Watchers** -- Configure fs.inotify.max_user_watches with RAM detection and custom input
- **Plymouth** -- Plymouth boot splash with spinner theme, GRUB splash parameter
- **Hibernate** -- Swap file + suspend-then-hibernate (coexists with zram, low priority swap)

### Package managers
- **System Upgrade** -- Update, dist-upgrade and autoremove in one step
- **APT Sources** -- Modernize to DEB822, toggle non-free/backports/deb-src/testing
- **Flatpak** -- Install Flatpak with Flathub repository
- **Nix** -- Install/remove Nix package manager (multi-user daemon, flakes toggle)
- **Homebrew** -- Install/remove Homebrew on Linux with automatic dependency setup

### SSH
- **OpenSSH Server** -- Install and manage openssh-server with service control
- **SSH Access** -- Toggle pubkey-only, pubkey+password, or password-only with root login control
- **SSH Keys** -- Generate ED25519 keys with suffix support for multiple identities
- **SSH Config** -- Manage `~/.ssh/config` entries for GitHub, GitLab, and custom servers
- **Commit Signing** -- Configure git commit signing with SSH keys, conditional `includeIf` for multi-identity setups

### Development

#### Environments
- **Node.js** -- fnm + Node.js LTS
- **Python** -- uv package manager
- **Rust** -- rustup/cargo
- **Go** -- Go via APT or official tarball

#### Tools
- **Build Essentials** -- Core compilation tools and development libraries
- **GitHub CLI** -- Official GitHub CLI (apt repo)
- **AWS CLI** -- AWS CLI v2 (binary installer)
- **Docker** -- Docker CE with post-install group management
- **HTTPie** -- Modern HTTP client
- **MongoDB Compass** -- MongoDB GUI (Flatpak)

#### AI
- **Claude Code** -- Anthropic CLI for Claude (npm global)
- **OpenCode** -- Terminal AI assistant (npm global)
- **GitHub Copilot CLI** -- AI-powered CLI (gh extension)
- **AI Resources** -- Curated list of AI tools for developers

### Shell
- **Starship** -- Cross-shell prompt
- **Zoxide** -- Smarter cd command
- **Atuin** -- Shell history search
- **Tmux** -- Terminal multiplexer
- **Zellij** -- Terminal workspace
- **Dotfiles** -- Clone and apply dotfiles via GNU Stow (portable, no lock-in)

### Hardware
- **Slimbook EVO** -- Install Slimbook repository and EVO/GNOME meta-packages

### Virtualization
- **QEMU/KVM** -- QEMU, libvirt, virt-manager with user groups, libvirtd service, and default network

### Software
- **Utilities** -- CLI utilities (fzf, bat, ripgrep, fd, htop, btop, jq, yq, etc.)
- **Media** -- Media tools and codecs
- **Editors** -- VS Code (with extensions management) and Neovim (LazyVim + dependencies wizard)
- **Terminals** -- Alacritty (build from source), Kitty (user-space installer), Ptyxis (APT)
- **Browsers** -- Brave, LibreWolf, Mullvad Browser, Chromium
- **Security**
  - **VPN** -- Mullvad VPN, Proton VPN
  - **Password Managers** -- Proton Pass, Proton Pass CLI, KeePassXC (Flatpak), Bitwarden CLI
  - **Authenticators** -- Proton Authenticator, Yubico Authenticator (Flatpak)
  - **Hardware Keys** -- YubiKey Manager, Nitrokey App2 (Flatpak)
  - **OpenPGP** -- gnupg, seahorse, scdaemon, pinentry-gnome3
- **Messaging** -- Telegram (Flatpak), Slack (Flatpak), Discord (Flatpak), Element (APT repo)
- **Productivity** -- GIMP (Flatpak), Inkscape (Flatpak), OnlyOffice (Flatpak), LibreOffice (APT), Nextcloud (Flatpak + Nautilus plugin), LocalSend (Flatpak), Balena Etcher (GitHub zip)
- **Fonts** -- Nerd Fonts (Noto, Symbols Only, Hack, CaskaydiaCove, FiraCode) from GitHub releases

### UI
- **Appearance**
  - **GTK Theme** -- Catppuccin Mocha GTK theme with accent color selection, dark mode toggle, GTK4/libadwaita symlinks
  - **Icons** -- Papirus icons with Catppuccin folder colors
  - **Cursors** -- Catppuccin Mocha cursors (variant selection)
  - **Terminal Profile** -- Catppuccin color profiles for GNOME Terminal
- **Keyboard** -- English intl layout (AltGr dead keys), 4 fixed workspaces, Super+W close, Super+Return terminal, Super+1-4/Shift+1-4 workspace switching
- **Terminal CSS** -- VTE terminal padding for GTK3 and GTK4
- **Extensions** -- Manage GNOME Shell extensions (Blur My Shell, Vitals, AppIndicator, Privacy Quick Settings, Quick Settings Audio Panel, User Themes)
- **Browser Themes** -- Catppuccin Mocha install guide for Brave, Chromium, Firefox, LibreWolf

### Diagnostics
- **Health check** -- System info, dependency status, and task overview
- **Log management** -- View, delete, and clean session logs

## Requirements

- Debian 13 (Trixie) or compatible
- [gum](https://github.com/charmbracelet/gum) -- auto-installed on first run if missing

## Install

On a fresh Debian install, `curl` and `git` are not available and the user has no sudo access. Install them as root first:

```bash
su -c 'apt-get install -y curl git'
```

Then install debian-setup:

```bash
curl -fsSL https://git.qwertee.link/ajmasia.dev/debian-setup/raw/branch/main/install.sh | bash
```

This clones the repo to `~/.local/share/debian-setup` and creates a symlink in `~/.local/bin`.

The first thing to do after launching is **System Essentials > Sudoers** to grant sudo access to your user (uses `su` with root password).

## Usage

```
debian-setup [options]

Options:
  -v, --version    Show version
  -h, --help       Show this help message
  --update         Update to latest version
  --uninstall      Remove debian-setup
```

Run without options to start the interactive menu. Navigate with arrow keys, confirm with Enter, go back with Escape, exit with Ctrl+C.

## Project structure

```
debian-setup/
├── debian-setup                    # Entry point
├── install.sh                      # Installer (curl | bash)
├── VERSION
├── CHANGELOG.md
├── src/
│   ├── lib/
│   │   ├── colors.sh              # Catppuccin Mocha palette
│   │   ├── gum.sh                 # Gum wrappers (choose, filter, input, SIGINT)
│   │   ├── log.sh                 # Logging (terminal + file)
│   │   ├── apt.sh                 # APT package list utilities
│   │   ├── system.sh              # System info queries
│   │   ├── ui.sh                  # UI components (persistent header, dirty flag)
│   │   └── xdg.sh                 # XDG Base Directory support
│   ├── modules/
│   │   ├── health.sh
│   │   ├── system/                 # Sudoers, Password Feedback, Editor,
│   │   │   ├── ...                 # Zram, Kernel, Watchers
│   │   ├── packages/               # APT Sources, Flatpak, Nix
│   │   │   ├── ...
│   │   ├── ssh/                    # Server, Access, Keys, Config, Signing
│   │   │   ├── ...
│   │   ├── development/            # Environments, Tools, AI
│   │   │   ├── main.sh            # Top-level aggregator
│   │   │   ├── environments.sh    # Node.js, Python, Rust, Go
│   │   │   ├── tools.sh           # Build, GitHub CLI, AWS CLI, Docker, ...
│   │   │   ├── ai.sh             # Claude Code, OpenCode, Copilot CLI, ...
│   │   │   ├── ...
│   │   ├── shell/                  # Starship, Zoxide, Atuin, Tmux, Zellij
│   │   │   ├── ...
│   │   ├── hardware/               # Slimbook EVO
│   │   │   ├── ...
│   │   ├── virtualization/         # QEMU/KVM
│   │   │   ├── ...
│   │   ├── software/               # Utilities, Media, Editors, Terminals,
│   │   │   ├── ...                 # Browsers, Security, Messaging, Productivity, Fonts
│   │   ├── gnome/                  # Appearance, Keyboard, Terminal CSS, Extensions, Browser Themes
│   │   │   ├── ...
│   │   └── diagnostics/            # Health check, Logs
│   │       ├── ...
│   └── menu.sh
├── packages/
│   ├── apt/                        # Package lists (build, utils, media, openpgp)
│   ├── gnome/
│   │   └── extensions.txt          # GNOME Shell extensions (uuid|label)
│   ├── fonts/
│   │   └── nerdfonts.txt           # Nerd Fonts (archive_name|label)
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
