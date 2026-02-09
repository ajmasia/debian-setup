# LibreOffice task (APT)

[[ -n "${_MOD_LIBREOFFICE_LOADED:-}" ]] && return 0
_MOD_LIBREOFFICE_LOADED=1

_LIBREOFFICE_LABEL="Configure LibreOffice"
_LIBREOFFICE_DESC="Install LibreOffice office suite."

_libreoffice::is_installed() {
    dpkg -l libreoffice-common 2>/dev/null | grep -q '^ii'
}

libreoffice::check() {
    _libreoffice::is_installed
}

libreoffice::status() {
    _libreoffice::is_installed || printf 'not installed'
}

libreoffice::apply() {
    local choice

    while true; do
        local installed=false
        _libreoffice::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > LibreOffice"
        log::break

        log::info "LibreOffice"

        if $installed; then
            local version
            version="$(dpkg -l libreoffice-common 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "LibreOffice: ${version}"
        else
            log::warn "LibreOffice (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove LibreOffice")
        else
            options+=("Install LibreOffice")
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
            "Install LibreOffice")
                log::break
                log::info "Installing LibreOffice"
                ui::flush_input
                if sudo apt-get install -y libreoffice </dev/tty; then
                    hash -r
                    log::ok "LibreOffice installed"
                else
                    log::error "Failed to install LibreOffice"
                fi
                ;;
            "Remove LibreOffice")
                log::break
                log::info "Removing LibreOffice"
                ui::flush_input
                if sudo apt-get remove -y libreoffice </dev/tty; then
                    hash -r
                    log::ok "LibreOffice removed"
                else
                    log::error "Failed to remove LibreOffice"
                fi
                ;;
        esac
    done
}
