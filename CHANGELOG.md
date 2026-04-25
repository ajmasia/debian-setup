# Changelog

All notable changes to this project will be documented in this file.

## [1.7.1] - 2026-04-25

### Added

- **Icons module** -- restored under UI; installs Papirus icon theme with options for Catppuccin folder colors, Papirus + Adwaita folders, and Papirus-Dark + Adwaita folders
- **Terminal CSS module** -- restored under UI; adds VTE terminal padding to GTK3 and GTK4 stylesheets, with apply/remove actions
- **Plymouth module** -- restored under System Essentials; manages boot splash with `spinner`, `bgrt` and custom `bgrt-luks` themes, plus optional community themes from `adi1090x/plymouth-themes`

## [1.6.9] - 2026-04-17

### Added

- **Slimbook desktop detection** -- installs `slimbook-meta-plasma` on KDE/Plasma sessions and `slimbook-meta-gnome` on GNOME (default); added `session::is_kde()` to system library

## [1.6.8] - 2026-04-17

### Added

- **Slimbook detection** -- `system::is_slimbook()` reads `/sys/class/dmi/id/sys_vendor`; the Slimbook EVO option is now hidden on non-Slimbook hardware

### Fixed

- **Update detection** -- synchronous version fetch replaces background async fetch, so notifications appear in the same session that triggers the check
- **Update cache refresh** -- when the installed version is ahead of the cached value (e.g. after a manual update), the cache is now refreshed immediately instead of being skipped

## [1.6.7] - 2026-04-17

### Fixed

- **Slimbook URLs** -- updated repository and GPG key download URLs to `debian/noble` branch (old `main` branch no longer contains these files)
- **Update detection** -- version cache now refreshes every session when installed version is ahead of or equal to cached version, ensuring new releases are detected promptly

## [1.6.6] - 2026-04-17

### Fixed

- **Menu header** -- removed `(ds)` hint from the title

## [1.6.5] - 2026-04-17

### Fixed

- **APT detection** -- backports, deb-src, non-free and component detection always returned false on DEB822 format due to a quoted glob preventing shell expansion; replaced with direct file reference (`_APT_SOURCES_FILE`) consistent with `_apt::has_testing`

## [1.6.4] - 2026-04-17

### Added

- **Update notifications** -- on startup, checks for a newer version in the background; shows `[info] ⚡ New version available: vX.X.X — run ds --update` when a new release is detected. Cache refreshes every 24h to avoid unnecessary network requests.

## [1.6.3] - 2026-04-17

### Added

- **Post-install guidance** -- installer success message now mentions `ds --completions` as next step
- **Menu header** -- shows `(ds)` shortcut hint in the main menu header
- **Completions feedback** -- shows "Generating task cache..." message while building the completion cache

### Fixed

- **Uninstall detection** -- `--uninstall` now also checks the `ds` symlink when deciding if the tool is installed

### Changed

- **README** -- gum listed as installed by the installer, not on first run

## [1.6.2] - 2026-04-17

### Fixed

- **Version and help** -- `--version` and `--help` always show `debian-setup` as the canonical name regardless of the command used (`ds` or `debian-setup`)

## [1.6.1] - 2026-04-17

### Added

- **gum auto-install** -- installer now installs gum automatically as it is a hard dependency

### Fixed

- **`ds` completions** -- bash lazy-loads completions by command name; added a dedicated `ds` symlink so tab completion works for both `ds` and `debian-setup`

## [1.6.0] - 2026-04-17

### Added

- **`ds` command** -- installer creates `ds` and `debian-setup` symlinks; both work identically
- **`--completions` flag** -- install shell completions from the CLI without entering the interactive menu; defaults to current shell

### Changed

- **Help and version** -- output now reflects the command name used to invoke the tool (`ds` or `debian-setup`)
- **Completions** -- registered for both `ds` and `debian-setup` automatically

## [1.5.2] - 2026-04-17

### Changed

- **Remote** -- origin migrated from self-hosted Gitea to GitHub (`github.com/ajmasia/debian-setup`)

## [1.5.1] - 2026-04-15

### Fixed

- **Slimbook on Ubuntu** -- use the same repo list URL as Debian (ubuntu-specific URL was failing); errors now remain visible for 2 seconds before the screen clears
- **GRUB on Ubuntu** -- Debian theme options (disable/enable/restore) hidden when not running Debian
- **Startup info** -- distro, available package managers and session log now displayed as three separate lines; removed duplicate OS line
- **Settings > About** -- new System section shows OS and available package managers

## [1.5.0] - 2026-04-15

### Added

- **Distro detection** -- detects the running distro at startup (`system::distro_id`) and exports `DISTRO_ID` for use across all modules
- **OS info at startup** -- displays the current OS as `[info]` on launch
- **Session detection** -- `session::is_gnome` detects active GNOME session to conditionally show GNOME-specific options
- **Ubuntu support** -- APT sources module adapts URIs, keyring, file name and components for Ubuntu; backports and deb-src toggles work on both Debian and Ubuntu
- **Compat filtering** -- optional sixth field `compat_fn` in task registry; tasks hidden when their compat function returns false

### Changed

- **UI category** renamed from "UI and Theming" to "UI"
- **Keyboard and Extensions** hidden outside GNOME sessions
- **Sudoers and Password Feedback** hidden on Ubuntu (handled by default)
- **Kernel backports** hidden on Ubuntu (Debian-only concept)
- **Slimbook** uses Ubuntu-specific repo list when running on Ubuntu
- **Startup display** shows distro info before session line, with a single blank line before the menu

### Removed

- **Appearance, Terminal CSS, Browser Themes, App Themes** modules removed (overly personal theming)
- **Plymouth** module removed
- **Hibernate** module removed

## [1.4.0] - 2026-04-06

### Added

- **Papirus + Adwaita Folders** -- new icon variant combining Papirus app icons with original Adwaita folder icons (light variant)
- **Papirus-Dark + Adwaita Folders** -- same combination using Papirus-Dark as base theme

## [1.3.0] - 2026-03-25

### Added

- **Latte flavor support** -- GTK theme now supports Mocha (dark) and Latte (light), with "Change Variant" option and automatic color scheme sync
- **Reset to Native GNOME** -- new option in Appearance to revert all theme customizations (GTK, Shell, icons, cursors, GTK4 CSS) back to Adwaita

## [1.2.0] - 2026-03-05

### Added

- **Calibre** module under Software > Productivity -- Flatpak install for e-book management
- **Custom Neovim config detection** -- scans ~/.config for Neovim configs with init.lua and offers alias setup

## [1.1.0] - 2026-02-25

### Added

- **Google Chrome** module under Software > Browsers -- APT repo install with GPG key management

## [1.0.0] - 2026-02-25

### Added

- **`--list` flag** -- print all available tasks to stdout (for scripting and shell completions)
- **`-o/--option` flag** -- jump directly to a task or category by name (case-insensitive substring match)
- **Shell completions** -- bash and zsh tab completion for flags and `-o` task names, cache-based via `~/.cache/debian-setup/tasks.txt`
- **Settings submenu** -- replaces Health with grouped CLI management: System Health, Logs, Completions, About
- **Completions manager** -- install/remove bash and zsh completions separately from Settings > Completions
- **About screen** -- version, install path, log directory, shell version
- **Customizable Neovim alias** -- prompt for alias name when adding Neovim configs to `.bash_aliases`
- **GTK Theme tweaks** -- macos (semaphore buttons), black, float (panel), outline (2px border) via `--tweaks`
- **Change Accent** option for GTK Theme, Icons (folder color), and Cursors (variant) without reinstalling
- **Window Buttons** module -- configure button layout with presets (right/left/macOS) or custom input
- **User Themes extension check** -- GTK Theme install verifies and offers to install the extension

### Changed

- **Search functions** refactored with shared helpers (`menu::_collect_leaf_tasks`, `menu::_run_choice`)
- **Health** renamed to **Settings** with simplified health check (machine status + group counters)
- **Health check** uses generic `health::_check_group` iterator instead of 9 duplicated functions

## [0.13.10] - 2026-02-25

### Added

- **Spotify** module under Software > Media -- APT repo install, desktop entry patch for GNOME native decorations
- **Node.js memory limit** configuration in Development > Node.js -- RAM-aware options with recommended value
- **Caffeine** GNOME Shell extension added to extensions list
- **Extensions Manager** and **Extensions app** install/remove options in GNOME Extensions wizard
- **GNOME Extensions** reworked -- D-Bus download via API, gsettings disable after install, uninstall support, individual APT tool management

### Changed

- **Main menu** reordered for logical new machine setup flow
- **Git** promoted to top-level menu (was under Development > Tools)
- **Kernel** moved from System Essentials to Hardware Support
- **Dotfiles** positioned before UI and Theming
- **Slimbook** label simplified (was "Slimbook EVO")
- **Claude Code** switched to native installer (was npm)

### Fixed

- Appthemes label variables renamed to avoid collision with module globals
- Health check memory percentage uses numeric `free` output for portability
- Browserthemes unnecessary while loop removed
- Spinner stopped on Ctrl+C to prevent orphaned subshell
- Unknown CLI flags rejected with error message
- `read` calls guarded against `set -e` in gum and ui libs
- Nerd Fonts OTF detection and breadcrumb path corrected
- APT Sources label capitalized to match Title Case convention
- Dead `vscode.txt` package list removed
- QEMU default network uses `sudo virsh` consistently and shows actual errors on failure
- Spotify moved to Software > Media sub-aggregator (was in Software root)
- Spotify GPG key updated and install error handling improved

## [0.13.8] - 2026-02-18

### Added

- **Obsidian** module under Software > Productivity -- note-taking app from GitHub .deb releases with auto-version detection, install/update/remove
- `fastfetch` added to CLI utilities package list

## [0.13.7] - 2026-02-17

### Added

- **Root support** -- auto-detect root user (`EUID == 0`) and define `sudo()` pass-through function so all modules work without modification when running as root (e.g., in a VM without sudo installed)
- Health check conditionally excludes `sudo` from dependency list when running as root

### Fixed

- Gum installer now auto-installs `gpg` if missing (minimal Debian installs may lack it)

## [0.13.6] - 2026-02-16

### Changed

- **LocalSend** switched from Flatpak to .deb from GitHub releases (latest version auto-detected), with tray icon dependency (`gir1.2-ayatanaappindicator3-0.1`)
- **LocalSend** wizard now offers "Update" option when already installed
- **Software** menu reordered: Browsers, Editors, Terminals, Productivity, Messaging first
- **Utilities** moved from Software to Shell Tools
- `cmatrix` added to CLI utilities package list

## [0.13.5] - 2026-02-14

### Added

- **Git** module under Development > Tools -- install/remove git, configure global settings (user.name, user.email, init.defaultBranch, pull.rebase, push.autoSetupRemote, fetch.prune, rerere.enabled, diff.colorMoved), configure local repository overrides, and large file guard (global pre-commit hook with configurable size limit)
- Help descriptions on optional git settings (e.g. "rebase instead of merge on pull")
- Gitconfig formatting: blank lines between sections after every write

## [0.13.4] - 2026-02-14

### Changed

- Fonts moved from Software to UI and Theming

## [0.13.3] - 2026-02-14

### Fixed

- SSH connection test now works for any server, not just GitHub/GitLab (uses SSH exit code instead of string matching)
- SSH Config now detects entries without `# comment` markers (manually added or from other tools)

## [0.13.2] - 2026-02-14

### Fixed

- Commit signing setup exits without allowing data input (missing stdin flush before input prompts)
- SSH Config verification fails when only one service is configured (now passes with any GitHub, GitLab, or custom server)
- Dotfiles select-to-apply loop breaks when a file conflict prompt appears (stdin consumed by heredoc)

### Added

- CaskaydiaMono Nerd Font to font list

## [0.13.0] - 2026-02-13

### Changed

- **Main menu reorganized**: new order — Hardware Support, Package Managers, System Essentials, Dotfiles, Shell Tools, OpenSSH Server, Development, UI and Theming, Software, Virtualization, Health
- **Dotfiles promoted to main menu** — accessible directly instead of through Shell submenu
- **Hardware renamed to "Hardware Support"** — clearer label
- **Shell renamed to "Shell Tools"** — clearer label
- **UI renamed to "UI and Theming"** — clearer label for GNOME customization module
- **Diagnostics renamed to "Health"** — shorter, more descriptive label
- All breadcrumbs updated to match new menu labels

## [0.13.1] - 2026-02-13

### Fixed

- SSH Config wizard crash on machines without `~/.ssh/config`

## [0.12.22] - 2026-02-13

### Added

- **Dotfiles** wizard now shows git repo status on entry (up to date, dirty, ahead/behind, diverged)
- Adopt prompt on conflict: when existing files collide with dotfiles, user chooses to replace with repo version or skip

### Changed

- Select to apply/remove now operates at individual item level for finer control
- Apply all uses GNU Stow at group level with conflict detection and adopt prompt
- All operations pause with Back/Exit after completion so results are visible

## [0.12.21] - 2026-02-13

### Changed

- **Dotfiles** module now uses GNU Stow for symlink management, ensuring full compatibility between debian-setup and standalone stow usage
- Apply/remove operates at group level (home, config, local/bin, local/share/completions)
- Show view displays group status (applied/partial/not applied) with per-item detail

## [0.12.20] - 2026-02-13

### Changed

- **Dotfiles** module rewritten with directory-based mapping structure (home, config, local/bin, local/share/completions)

## [0.12.19] - 2026-02-13

### Changed

- App Themes now prompt before writing to dotfiles — theme files are downloaded first, then user confirms whether to apply config (btop, Alacritty, Atuin, bat, cava, lazygit, Starship)

## [0.12.18] - 2026-02-13

### Fixed

- Standalone Papirus install now reinstalls the APT package to clear leftover Catppuccin folder color overrides from a previous full install

## [0.12.17] - 2026-02-13

### Added

- **Icons** wizard now offers "Install Papirus" standalone option alongside the existing "Install Papirus + Catppuccin" for users who want the icon theme without Catppuccin folder colors

## [0.12.16] - 2026-02-13

### Added

- **Nala** module under Package Managers -- install/remove Nala, a prettier APT frontend with parallel downloads and a cleaner interface

## [0.12.15] - 2026-02-11

### Added

- **App Themes** rewritten from informational to functional sub-aggregator with install/remove support for Catppuccin Mocha themes: btop, Alacritty, Atuin, bat, cava, eza, lazygit, and Starship
- Marker-based config management (`# debian-setup: catppuccin-mocha start/end`) for safe insert/remove of theme blocks
- Accent color selection (14 Catppuccin accents) for Atuin, eza, and lazygit themes
- Dual marker support for Starship (palette line + palette table)
- `batcat` detection for Debian (fallback to `bat`)
- Theme activation in btop config (`color_theme`), Alacritty (`general.import`), Atuin (`[theme]`), bat (`--theme`), and Starship (`palette`)
- **eza** added to CLI utilities package list

## [0.12.14] - 2026-02-11

### Added

- **App Themes** informational module in UI with Catppuccin Mocha install guides for btop, Alacritty, Atuin, bat, cava, eza, lazygit, and Starship

## [0.12.13] - 2026-02-11

### Added

- **GRUB silent boot** option to hide all boot messages after GRUB — adds `quiet`, `loglevel=0`, `systemd.show_status=false`, and `vt.global_cursor_default=0` to kernel command line, with enable/disable toggle and restore defaults support

## [0.12.12] - 2026-02-11

### Added

- Darth Vader and Motion community Plymouth themes

## [0.12.11] - 2026-02-11

### Added

- **Community Plymouth themes** from adi1090x/plymouth-themes -- install, remove, and select from 8 curated themes (Circle, Circle Alt, Deus Ex, Hexagon HUD, Lone, Loader 2, Spinner Alt, Rings 2) integrated into the existing Plymouth wizard
- Community theme list in `packages/plymouth/themes.txt` for easy customization

## [0.12.10] - 2026-02-10

### Added

- APT installation method for Nextcloud Desktop (`nextcloud-desktop`) as alternative to Flatpak, with independent install/remove per method

## [0.12.9] - 2026-02-10

### Added

- GRUB boot resolution inheritance option (`GRUB_GFXPAYLOAD_LINUX=keep`) to carry GRUB resolution through kernel console and Plymouth

## [0.12.8] - 2026-02-10

### Fixed

- Plymouth bgrt-luks theme files now created before already-set check (fixes theme selected but files missing on disk)

## [0.12.7] - 2026-02-10

### Fixed

- GRUB background removal now disables `05_debian_theme` via `chmod -x` (previous `GRUB_BACKGROUND=""` approach did not work)
- Plymouth bgrt-luks dialog moved below manufacturer logo to avoid overlap

## [0.12.6] - 2026-02-10

### Added

- **Plymouth bgrt-luks theme** -- custom theme that keeps manufacturer logo visible during LUKS password prompt (`DialogClearsFirmwareBackground=false`)

### Fixed

- GRUB background detection now checks generated `grub.cfg` (catches `desktop-base` / `05_debian_theme` backgrounds)
- GRUB resolution selector shows detected display modes filtered to common presets with recommendation

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

- **Dotfiles module** under Shell -- clone and apply dotfiles via symlinks
  - Clone repo to `~/.dotfiles`, apply/remove individual items
  - Built-in help with repo structure guide

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
