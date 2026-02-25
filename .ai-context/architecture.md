# Architecture

## Entry point (`debian-setup`)

- `set -euo pipefail` + trap SIGINT (exit 130)
- Resolves symlinks to get `SCRIPT_DIR`, reads `VERSION`
- When running as root, defines a pass-through `sudo()`
- Sources in strict order: colors > xdg > log > system > gum > ui > apt (lib) > menu > all modules
- Parses CLI flags, calls `gum::check` (auto-installs gum if missing), paints `ui::header`
- Routes to: `menu::main`, `menu::search`, `menu::search_to_install`, `menu::search_to_remove`

## Menu system (`src/menu.sh`)

- `menu::main()` — 11 top-level categories via `gum::filter` (height 14)
- `menu::search()` — flat list of all leaf tasks from 34 `_*_TASKS` arrays (listed in `_SEARCH_ARRAYS`)
- `menu::search_to_install()` / `menu::search_to_remove()` — filtered by `check_fn` result
- Leaf tasks end in `::apply`, sub-aggregators end in `::run`
- Escape/empty string = Back. On main menu = Exit
- All menus include "Back" and "Exit" at the end
- `gum::choose` for small menus (<5 items), `gum::filter` for large (5+ items)
- Module `run()` functions do NOT run checks — show simple labels (strip "Configure ")

## Persistent header

Painted once. `_UI_CONTENT_ROW` stores the cursor row (via `\033[6n`, 1-indexed). `ui::clear_content` uses `tput cup $((_UI_CONTENT_ROW - 1)) 0` + `tput ed` (0-indexed). If the terminal has scrolled (after apt-get, sudo, etc.), `_UI_DIRTY=1` triggers a full header repaint. The flag is set in `ui::flush_input`.

## Ctrl+C

`trap 'printf "\n"; exit 130' INT` in entry point. Wrappers propagate exit 130.

## Always-visible modules

Hardware Support, Package Managers, System Essentials, Dotfiles, Shell Tools, OpenSSH Server, Development, UI and Theming, Software, Virtualization, Health — always shown in main menu. No status logging at startup.
