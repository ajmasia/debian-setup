# OnlyOffice task (Flatpak)

[[ -n "${_MOD_ONLYOFFICE_LOADED:-}" ]] && return 0
_MOD_ONLYOFFICE_LOADED=1

_ONLYOFFICE_LABEL="Configure OnlyOffice"
_ONLYOFFICE_DESC="Install OnlyOffice Desktop Editors."
_ONLYOFFICE_FLATPAK_ID="org.onlyoffice.desktopeditors"

_onlyoffice::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_ONLYOFFICE_FLATPAK_ID"
}

onlyoffice::check() {
    _onlyoffice::is_installed
}

onlyoffice::status() {
    _onlyoffice::is_installed || printf 'not installed'
}

onlyoffice::apply() {
    local choice

    while true; do
        local installed=false
        _onlyoffice::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > OnlyOffice"
        log::break

        log::info "OnlyOffice"

        if $installed; then
            local version
            version="$(flatpak info "$_ONLYOFFICE_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "OnlyOffice: ${version}"
        else
            log::warn "OnlyOffice (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove OnlyOffice")
        else
            options+=("Install OnlyOffice")
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
            "Install OnlyOffice")
                log::break
                _onlyoffice::install
                ;;
            "Remove OnlyOffice")
                log::break
                _onlyoffice::remove
                ;;
        esac
    done
}

_onlyoffice::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing OnlyOffice"
    if flatpak install -y flathub "$_ONLYOFFICE_FLATPAK_ID"; then
        log::ok "OnlyOffice installed"
    else
        log::error "Failed to install OnlyOffice"
    fi
    ui::return_or_exit
}

_onlyoffice::remove() {
    log::info "Removing OnlyOffice"
    if flatpak remove -y "$_ONLYOFFICE_FLATPAK_ID"; then
        log::ok "OnlyOffice removed"
    else
        log::error "Failed to remove OnlyOffice"
    fi
    ui::return_or_exit
}
