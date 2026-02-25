# Modules

## Hierarchy (3 levels)

1. **Top-level aggregators** (`development/main.sh`, `software/main.sh`) — iterate sub-registries via `local -n tasks_ref`, implement `log_status()` and `has_pending()`
2. **Sub-aggregators** (`environments.sh`, `browsers.sh`, `tools.sh`, `appearance.sh`, etc.) — own `_*_TASKS` array, implement `check/status/run`
3. **Leaf modules** — implement `check/status/apply`, do the actual work

## Settings modules

- `settings/main.sh` — submenu: System Health, Logs, Completions, About
- `settings/completions.sh` — install/remove bash and zsh completion symlinks separately
- `settings/about.sh` — version, install path, log dir, shell
- `settings/logs.sh` — log file viewer

## Appearance modules

- `gnome/gtktheme.sh` — Catppuccin GTK theme with accent chooser, tweaks (macos/black/float/outline), User Themes extension check
- `gnome/icons.sh` — Papirus icons with Catppuccin folder colors, change folder color
- `gnome/cursors.sh` — Catppuccin cursors with variant chooser, change variant
- `gnome/windowbuttons.sh` — window button layout presets (right/left/custom)
- `gnome/termprofile.sh` — GNOME Terminal color profile
- `gnome/appearance.sh` — sub-aggregator for the above

## Adding a new leaf module

1. Create `src/modules/<category>/<name>.sh` with load guard
2. Define `_NAME_LABEL="Configure Foo"`, `_NAME_DESC="..."`
3. Implement `foo::check()`, `foo::status()`, `foo::apply()`
4. For APT-based modules, delegate to `apt::list_wizard` / `apt::deb_wizard`
5. Add entry to the parent's `_*_TASKS` array
6. Source the file in the `debian-setup` entry point (in correct module order)
7. For search support, ensure the parent `_*_TASKS` array is in `_SEARCH_ARRAYS` in `src/menu.sh`

## Example: simple leaf module (APT-based)

```bash
[[ -n "${_MOD_FOO_LOADED:-}" ]] && return 0
declare -g _MOD_FOO_LOADED=1

_FOO_LABEL="Configure Foo"
_FOO_DESC="Install foo packages."
_FOO_LIST="${SCRIPT_DIR}/packages/apt/foo.txt"

foo::check() { apt::list_check "$_FOO_LIST"; }
foo::status() { apt::list_status "$_FOO_LIST"; }
foo::apply() { apt::list_wizard "Category > Configure Foo" "Foo packages" "$_FOO_LIST"; }
```

## Example: sub-aggregator

```bash
_CATEGORY_TASKS=(
    "${_FOO_LABEL}|_FOO_DESC|foo::check|foo::apply|foo::status"
    "${_BAR_LABEL}|_BAR_DESC|bar::check|bar::apply|bar::status"
)

category::check() {
    for task in "${_CATEGORY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || return 1
    done
}

category::status() {
    local pending=0
    for task in "${_CATEGORY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    [[ $pending -gt 0 ]] && printf '%s items pending' "$pending"
}

category::run() {
    while true; do
        # build menu from _CATEGORY_TASKS, strip "Configure " prefix
        # gum::choose or gum::filter depending on count
        # Back/Exit handling
    done
}
```

## Package lists

- `packages/apt/*.txt` — APT lists (one package per line, comments with #)
- `packages/deb/*.txt` — direct .deb URLs (format `name|url`)
- `packages/vscode/extensions.txt` — VS Code extensions (`id|label`)
- `packages/gnome/extensions.txt` — GNOME Shell extensions (`uuid|label`)
- `packages/fonts/nerdfonts.txt` — Nerd Fonts (`archive_name|label`)
- `packages/plymouth/themes.txt` — Plymouth themes (`dir_name|label|pack`)
