# Libraries (`src/lib/`)

## Sourcing order

colors > xdg > log > system > gum > ui > apt

## Reference

| File | Load guard | Key exports |
|------|-----------|------------|
| `colors.sh` | `_LIB_COLORS_LOADED` | `COLOR_*`, `HEX_*` constants (Catppuccin Mocha: base, mantle, crust, surface0-2, overlay0-2, rosewater, flamingo, pink, mauve, red, maroon, peach, yellow, green, teal, sky, sapphire, blue, lavender) |
| `xdg.sh` | `_LIB_XDG_LOADED` | `xdg::state_dir`, `xdg::log_dir`, `xdg::log_file`, `xdg::init` |
| `log.sh` | `_LIB_LOG_LOADED` | `log::info/ok/warn/error` (terminal+file), `log::nav` (terminal only), `log::break` |
| `system.sh` | `_LIB_SYSTEM_LOADED` | `system::hostname/kernel/os/arch/cpu/ram_total/uptime` |
| `gum.sh` | `_LIB_GUM_LOADED` | `gum::check` (auto-install), `gum::choose/filter/input` (SIGINT-safe wrappers) |
| `ui.sh` | `_LIB_UI_LOADED` | `ui::header/clear/clear_content/spin_start/spin_stop/flush_input/session_info/goodbye/return_or_exit` |
| `apt.sh` | `_LIB_APT_LOADED` | `apt::read_list/is_installed/pending_from_list/install_list/list_check/list_status/list_wizard` + `apt::read_deb_list/deb_pending/deb_check/deb_status/deb_install/deb_wizard` |
