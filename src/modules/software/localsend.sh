# LocalSend task (Flatpak)

[[ -n "${_MOD_LOCALSEND_LOADED:-}" ]] && return 0
_MOD_LOCALSEND_LOADED=1

_LOCALSEND_LABEL="Configure LocalSend"
_LOCALSEND_DESC="Install LocalSend for local network file sharing."
_LOCALSEND_FLATPAK_ID="org.localsend.localsend_app"

_localsend::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_LOCALSEND_FLATPAK_ID"
}

localsend::check() {
    _localsend::is_installed
}

localsend::status() {
    _localsend::is_installed || printf 'not installed'
}

localsend::apply() {
    local choice

    while true; do
        local installed=false
        _localsend::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > LocalSend"
        log::break

        log::info "LocalSend"

        if $installed; then
            local version
            version="$(flatpak info "$_LOCALSEND_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "LocalSend: ${version}"
        else
            log::warn "LocalSend (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove LocalSend")
        else
            options+=("Install LocalSend")
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
            "Install LocalSend")
                log::break
                _localsend::install
                ;;
            "Remove LocalSend")
                log::break
                _localsend::remove
                ;;
        esac
    done
}

_localsend::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing LocalSend"
    if sudo flatpak install -y flathub "$_LOCALSEND_FLATPAK_ID"; then
        log::ok "LocalSend installed"
    else
        log::error "Failed to install LocalSend"
    fi
    ui::return_or_exit
}

_localsend::remove() {
    log::info "Removing LocalSend"
    if sudo flatpak remove -y "$_LOCALSEND_FLATPAK_ID"; then
        log::ok "LocalSend removed"
    else
        log::error "Failed to remove LocalSend"
    fi
    ui::return_or_exit
}
