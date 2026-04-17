<p align="center">
  <img src="https://www.debian.org/logos/openlogo-nd.svg" alt="Debian" width="100">
</p>

# Debian Setup Script

![Version](https://img.shields.io/badge/version-1.5.2-blue)
![Platform](https://img.shields.io/badge/platform-Debian%2013-A81D33?logo=debian)
![Ubuntu](https://img.shields.io/badge/ubuntu-experimental-E95420?logo=ubuntu&logoColor=white)
![Shell](https://img.shields.io/badge/shell-bash-4EAA25?logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

Post-install automation for the impatient developer.

Interactive CLI tool that automates common Debian post-installation tasks: system configuration, package managers, development environments, virtualization, software installation, and more.

> Ubuntu support is actively being developed. Most modules work on Ubuntu 24.04+, with ongoing work to adapt distro-specific options (APT sources, GRUB, sudoers, kernel backports).

## Requirements

- Debian 13 (Trixie) — primary target
- Ubuntu 24.04+ — experimental
- [gum](https://github.com/charmbracelet/gum) — auto-installed on first run if missing

## Install

On a fresh Debian install, `curl` and `git` are not available and the user has no sudo access. Install them as root first:

```bash
su -c 'apt-get install -y curl git'
```

Then install debian-setup:

```bash
curl -fsSL https://raw.githubusercontent.com/ajmasia/debian-setup/main/install.sh | bash
```

This clones the repo to `~/.local/share/debian-setup` and creates two symlinks in `~/.local/bin`: `ds` (short) and `debian-setup` (long form).

> On a fresh install, start with **System Essentials > Sudoers** to grant sudo access to your user (uses `su` with the root password).

### Shell completions

After installing, enable tab completions for your shell:

```bash
debian-setup --completions        # current shell
debian-setup --completions bash   # bash
debian-setup --completions zsh    # zsh
```

Restart your shell to activate them.

## Usage

```
debian-setup [options]

Options:
  -v, --version             Show version
  -h, --help                Show this help message
  -s, --search              Global search across all tasks
  -si, --search-to-install  Search only tasks not yet applied
  -sr, --search-to-remove   Search only applied/installed tasks
  -l, --list                List all tasks (generates completion cache)
  -o, --option <name>       Jump directly to a task or category
  --completions [bash|zsh]  Install shell completions (default: current shell)
  --update                  Update to latest version
  --uninstall               Remove debian-setup
```

Run without options to start the interactive menu. Navigate with arrow keys, confirm with Enter, go back with Escape, exit with Ctrl+C.

## Features

### Hardware Support
- **Slimbook EVO** -- Slimbook repository and EVO/GNOME meta-packages

### System Essentials
- **Sudoers / Password Feedback / Default Editor** -- user privileges and environment basics
- **Zram Swap** -- compressed RAM swap (zstd)
- **Kernel** -- switch between stable and backports kernel
- **Inotify Watchers** -- configure `fs.inotify.max_user_watches`
- **Plymouth** -- boot splash with theme selection (spinner, bgrt, bgrt-luks, community themes)
- **GRUB** -- resolution, silent boot, Debian theme toggle
- **Hibernate** -- swap file + suspend-then-hibernate (coexists with zram)

### Package Managers
- **System Upgrade** -- update, dist-upgrade and autoremove in one step
- **APT Sources** -- DEB822 format, non-free/backports/deb-src/testing toggles
- **Flatpak** -- Flatpak with Flathub
- **Nala / Nix / Homebrew** -- alternative package manager options

### OpenSSH Server
- **Server** -- install and manage openssh-server with service control
- **Access** -- toggle pubkey-only, pubkey+password, or password-only
- **Keys** -- generate ED25519 keys with multi-identity suffix support
- **Config** -- manage `~/.ssh/config` entries (GitHub, GitLab, custom servers)
- **Commit Signing** -- SSH-based git signing with `includeIf` for multiple identities

### Development
- **Environments** -- Node.js (fnm), Python (uv), Rust (rustup), Go
- **Tools** -- Git (global config + signing), Build Essentials, GitHub CLI, AWS CLI v2, Docker CE, HTTPie, MongoDB Compass
- **AI** -- Claude Code, OpenCode, GitHub Copilot CLI

### Dotfiles
- Clone and apply dotfiles via GNU Stow

### Shell Tools
- **Utilities** -- fzf, bat, eza, ripgrep, fd, htop, btop, jq, yq, fastfetch, and more
- **Starship / Zoxide / Atuin / Tmux / Zellij** -- prompt, navigation and shell history

### Virtualization
- **QEMU/KVM** -- QEMU, libvirt, virt-manager with user groups and default network

### Software
- **Browsers** -- Brave, LibreWolf, Mullvad Browser, Chromium, Chrome
- **Editors** -- VS Code (with extensions), Neovim (LazyVim)
- **Terminals** -- Alacritty, Kitty, Ptyxis
- **Productivity** -- GIMP, Inkscape, OnlyOffice, LibreOffice, Nextcloud, Obsidian, Calibre, LocalSend, Etcher
- **Messaging** -- Telegram, Slack, Discord, Element
- **Security** -- Mullvad VPN, Proton VPN, Proton Pass, KeePassXC, Bitwarden, YubiKey, Nitrokey, OpenPGP
- **Fonts** -- Nerd Fonts (Noto, Hack, CaskaydiaCove, CaskaydiaMono, FiraCode, Symbols Only)

### UI and Theming
- **Appearance** -- Catppuccin Mocha GTK theme, Papirus icons with folder colors, Catppuccin cursors, GNOME Terminal profile
- **Keyboard** -- English intl layout, workspace switching, custom shortcuts
- **Extensions** -- Blur My Shell, Vitals, AppIndicator, User Themes, and more
- **App Themes** -- Catppuccin Mocha for btop, Alacritty, Atuin, bat, eza, lazygit, Starship
- **Fonts** -- Nerd Fonts from GitHub releases

### Settings
- **Health Check** -- system info, dependency status, task overview
- **Logs** -- view and clean session logs
- **Completions** -- install/remove bash and zsh completions
- **About** -- version, install path, shell, package managers

## Architecture

```
debian-setup/
├── debian-setup                    # Entry point
├── install.sh                      # Installer and updater (curl | bash)
├── VERSION
├── CHANGELOG.md
├── completions/
│   ├── debian-setup.bash
│   └── debian-setup.zsh
├── src/
│   ├── lib/
│   │   ├── colors.sh              # Catppuccin Mocha palette
│   │   ├── gum.sh                 # gum wrappers (choose, filter, input, SIGINT)
│   │   ├── log.sh                 # Logging (terminal + file)
│   │   ├── apt.sh                 # APT list and .deb utilities
│   │   ├── system.sh              # System info (OS, distro, hardware)
│   │   ├── ui.sh                  # Persistent header, dirty flag, spin
│   │   └── xdg.sh                 # XDG Base Directory support
│   ├── menu.sh                    # Main menu, search, jump, task registry
│   └── modules/
│       ├── system/                # Sudoers, Editor, Zram, Kernel, GRUB, Plymouth, Hibernate
│       ├── packages/              # Upgrade, APT Sources, Flatpak, Nala, Nix, Homebrew
│       ├── ssh/                   # Server, Access, Keys, Config, Signing
│       ├── development/           # Environments, Tools, AI
│       ├── shell/                 # Utilities, Starship, Zoxide, Atuin, Tmux, Zellij, Dotfiles
│       ├── hardware/              # Slimbook EVO
│       ├── virtualization/        # QEMU/KVM
│       ├── software/              # Browsers, Editors, Terminals, Productivity, Messaging, Security, Fonts
│       ├── gnome/                 # Appearance, Keyboard, Extensions, CSS
│       └── settings/              # Health, Logs, Completions, About
└── packages/
    ├── apt/                       # APT package lists (one per line)
    ├── deb/                       # Direct .deb installers (name|url)
    ├── gnome/extensions.txt       # GNOME Shell extensions (uuid|label)
    ├── fonts/nerdfonts.txt        # Nerd Fonts (archive_name|label)
    ├── plymouth/themes.txt        # Plymouth community themes
    └── vscode/extensions.txt      # VS Code extensions (id|label)
```

Each module follows a consistent three-function pattern: `check` (returns 0 if already configured), `status` (human-readable description of pending work), and `apply` (interactive wizard). Top-level categories aggregate modules via task registries, enabling the global search and health check features.

## Design

- **Catppuccin Mocha** color palette throughout
- **XDG compliant** -- logs stored in `$XDG_STATE_HOME/debian-setup/logs/`
- **Session logging** -- all actions recorded to daily log files
- **Wizard pattern** -- each task shows current status and offers contextual actions
- **Non-destructive** -- every configuration change can be undone from the same menu
- **Repo cleanup** -- removing packages with external repos also removes the repo and GPG key
- **Ctrl+C safe** -- clean exit from any prompt via SIGINT handling
- **Distro-aware** -- options hidden or adapted based on the running distribution
