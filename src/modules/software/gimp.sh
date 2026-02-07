# GIMP task (Flatpak)

[[ -n "${_MOD_GIMP_LOADED:-}" ]] && return 0
_MOD_GIMP_LOADED=1

_GIMP_LABEL="Configure GIMP"
_GIMP_DESC="Install GIMP image editor."
_GIMP_FLATPAK_ID="org.gimp.GIMP"

_gimp::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_GIMP_FLATPAK_ID"
}

gimp::check() {
    _gimp::is_installed
}

gimp::status() {
    _gimp::is_installed || printf 'not installed'
}

gimp::apply() {
    local choice

    while true; do
        local installed=false
        _gimp::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > GIMP"
        log::break

        log::info "GIMP"

        if $installed; then
            local version
            version="$(flatpak info "$_GIMP_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "GIMP: ${version}"
        else
            log::warn "GIMP (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove GIMP")
        else
            options+=("Install GIMP")
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
            "Install GIMP")
                log::break
                _gimp::install
                ;;
            "Remove GIMP")
                log::break
                _gimp::remove
                ;;
        esac
    done
}

_gimp::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        return
    fi

    log::info "Installing GIMP"
    if flatpak install -y flathub "$_GIMP_FLATPAK_ID"; then
        log::ok "GIMP installed"
    else
        log::error "Failed to install GIMP"
    fi
}

_gimp::remove() {
    log::info "Removing GIMP"
    if flatpak remove -y "$_GIMP_FLATPAK_ID"; then
        log::ok "GIMP removed"
    else
        log::error "Failed to remove GIMP"
    fi
}
