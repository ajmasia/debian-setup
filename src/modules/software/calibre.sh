# Calibre task (Flatpak)

[[ -n "${_MOD_CALIBRE_LOADED:-}" ]] && return 0
_MOD_CALIBRE_LOADED=1

_CALIBRE_LABEL="Configure Calibre"
_CALIBRE_DESC="Install Calibre e-book manager."
_CALIBRE_FLATPAK_ID="com.calibre_ebook.calibre"

_calibre::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_CALIBRE_FLATPAK_ID"
}

calibre::check() {
    _calibre::is_installed
}

calibre::status() {
    _calibre::is_installed || printf 'not installed'
}

calibre::apply() {
    local choice

    while true; do
        local installed=false
        _calibre::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > Calibre"
        log::break

        log::info "Calibre"

        if $installed; then
            local version
            version="$(flatpak info "$_CALIBRE_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Calibre: ${version}"
        else
            log::warn "Calibre (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Calibre")
        else
            options+=("Install Calibre")
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
            "Install Calibre")
                log::break
                _calibre::install
                ;;
            "Remove Calibre")
                log::break
                _calibre::remove
                ;;
        esac
    done
}

_calibre::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Calibre"
    if sudo flatpak install -y flathub "$_CALIBRE_FLATPAK_ID"; then
        log::ok "Calibre installed"
    else
        log::error "Failed to install Calibre"
    fi
    ui::return_or_exit
}

_calibre::remove() {
    log::info "Removing Calibre"
    if sudo flatpak remove -y "$_CALIBRE_FLATPAK_ID"; then
        log::ok "Calibre removed"
    else
        log::error "Failed to remove Calibre"
    fi
    ui::return_or_exit
}
