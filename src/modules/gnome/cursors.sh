# Catppuccin Cursors task

[[ -n "${_MOD_GNOME_CURSORS_LOADED:-}" ]] && return 0
_MOD_GNOME_CURSORS_LOADED=1

_GNOME_CURSORS_LABEL="Configure Cursors"
_GNOME_CURSORS_DESC="Install Catppuccin Mocha cursors."

_GNOME_CURSORS_BASE_URL="https://github.com/catppuccin/cursors/releases/latest/download"
_GNOME_CURSORS_ICONS_DIR="$HOME/.local/share/icons"

_gnome_cursors::is_installed() {
    local current
    current="$(gsettings get org.gnome.desktop.interface cursor-theme 2>/dev/null || true)"
    [[ "$current" == *"catppuccin-mocha"* ]]
}

_gnome_cursors::find_installed() {
    local dir
    for dir in "$_GNOME_CURSORS_ICONS_DIR"/catppuccin-mocha-*-cursors; do
        if [[ -d "$dir" ]]; then
            basename "$dir"
            return 0
        fi
    done
    return 1
}

gnome_cursors::check() {
    _gnome_cursors::is_installed
}

gnome_cursors::status() {
    _gnome_cursors::is_installed || printf 'not installed'
}

gnome_cursors::apply() {
    local choice

    while true; do
        local installed=false cursor_name=""
        _gnome_cursors::is_installed && installed=true
        cursor_name="$(_gnome_cursors::find_installed 2>/dev/null || true)"

        ui::clear_content
        log::nav "GNOME > Appearance > Cursors"
        log::break

        log::info "Catppuccin Cursors"

        if $installed && [[ -n "$cursor_name" ]]; then
            log::ok "Cursor theme: ${cursor_name}"
        elif [[ -n "$cursor_name" ]]; then
            log::warn "Installed but not active: ${cursor_name}"
        else
            log::warn "Catppuccin cursors (not installed)"
        fi

        log::break

        local options=()

        if [[ -z "$cursor_name" ]]; then
            options+=("Install Catppuccin Cursors")
        else
            if ! $installed; then
                options+=("Apply Catppuccin Cursors")
            fi
            options+=("Remove Catppuccin Cursors")
        fi

        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select a change to apply:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${options[@]}")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            "Install Catppuccin Cursors")
                log::break
                _gnome_cursors::install
                ;;
            "Apply Catppuccin Cursors")
                log::break
                gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
                log::ok "Cursor theme applied: ${cursor_name}"
                ;;
            "Remove Catppuccin Cursors")
                log::break
                _gnome_cursors::remove "$cursor_name"
                ;;
        esac
    done
}

_gnome_cursors::install() {
    # Choose variant
    local variant
    variant="$(gum::choose \
        --header "Select cursor variant:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "dark" "lavender" "blue" "mauve" "pink" "rosewater" "flamingo" \
        "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire" "light")"

    if [[ -z "$variant" ]]; then
        return
    fi

    local cursor_name="catppuccin-mocha-${variant}-cursors"
    local url="${_GNOME_CURSORS_BASE_URL}/${cursor_name}.zip"

    log::info "Downloading ${cursor_name}"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! curl -fsSL "$url" -o "$tmpdir/cursors.zip"; then
        log::error "Failed to download cursors"
        rm -rf "$tmpdir"
        return
    fi

    mkdir -p "$_GNOME_CURSORS_ICONS_DIR"

    # Remove previous catppuccin cursor theme if any
    rm -rf "$_GNOME_CURSORS_ICONS_DIR"/catppuccin-mocha-*-cursors 2>/dev/null || true

    if ! unzip -qo "$tmpdir/cursors.zip" -d "$_GNOME_CURSORS_ICONS_DIR/"; then
        log::error "Failed to extract cursors"
        rm -rf "$tmpdir"
        return
    fi

    rm -rf "$tmpdir"

    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_name"
    log::ok "Cursors installed and applied: ${cursor_name}"
}

_gnome_cursors::remove() {
    local cursor_name="$1"

    log::info "Removing Catppuccin cursors"
    rm -rf "$_GNOME_CURSORS_ICONS_DIR/$cursor_name" 2>/dev/null || true
    gsettings reset org.gnome.desktop.interface cursor-theme 2>/dev/null || true
    log::ok "Cursors removed and reverted"
}
