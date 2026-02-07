# Inkscape task (Flatpak)

[[ -n "${_MOD_INKSCAPE_LOADED:-}" ]] && return 0
_MOD_INKSCAPE_LOADED=1

_INKSCAPE_LABEL="Configure Inkscape"
_INKSCAPE_DESC="Install Inkscape vector graphics editor."
_INKSCAPE_FLATPAK_ID="org.inkscape.Inkscape"

_inkscape::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_INKSCAPE_FLATPAK_ID"
}

inkscape::check() {
    _inkscape::is_installed
}

inkscape::status() {
    _inkscape::is_installed || printf 'not installed'
}

inkscape::apply() {
    local choice

    while true; do
        local installed=false
        _inkscape::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > Inkscape"
        log::break

        log::info "Inkscape"

        if $installed; then
            local version
            version="$(flatpak info "$_INKSCAPE_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Inkscape: ${version}"
        else
            log::warn "Inkscape (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Inkscape")
        else
            options+=("Install Inkscape")
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
            "Install Inkscape")
                log::break
                _inkscape::install
                ;;
            "Remove Inkscape")
                log::break
                _inkscape::remove
                ;;
        esac
    done
}

_inkscape::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        return
    fi

    log::info "Installing Inkscape"
    if flatpak install -y flathub "$_INKSCAPE_FLATPAK_ID"; then
        log::ok "Inkscape installed"
    else
        log::error "Failed to install Inkscape"
    fi
}

_inkscape::remove() {
    log::info "Removing Inkscape"
    if flatpak remove -y "$_INKSCAPE_FLATPAK_ID"; then
        log::ok "Inkscape removed"
    else
        log::error "Failed to remove Inkscape"
    fi
}
