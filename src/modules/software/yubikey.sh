# YubiKey Manager task

[[ -n "${_MOD_YUBIKEY_LOADED:-}" ]] && return 0
_MOD_YUBIKEY_LOADED=1

_YUBIKEY_LABEL="Configure YubiKey Manager"
_YUBIKEY_DESC="Install YubiKey Manager."

_yubikey::is_installed() {
    dpkg -l yubikey-manager 2>/dev/null | grep -q '^ii'
}

yubikey::check() {
    _yubikey::is_installed
}

yubikey::status() {
    _yubikey::is_installed || printf 'not installed'
}

yubikey::apply() {
    local choice

    while true; do
        local installed=false
        _yubikey::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Hardware Keys > YubiKey Manager"
        log::break

        log::info "YubiKey Manager"

        if $installed; then
            local version
            version="$(dpkg -l yubikey-manager 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "YubiKey Manager: ${version}"
        else
            log::warn "YubiKey Manager (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove YubiKey Manager")
        else
            options+=("Install YubiKey Manager")
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
            "Install YubiKey Manager")
                log::break
                log::info "Installing YubiKey Manager"
                ui::flush_input
                if sudo apt-get install -y yubikey-manager </dev/tty; then
                    hash -r
                    log::ok "YubiKey Manager installed"
                else
                    log::error "Failed to install YubiKey Manager"
                fi
                ;;
            "Remove YubiKey Manager")
                log::break
                log::info "Removing YubiKey Manager"
                ui::flush_input
                if sudo apt-get remove -y yubikey-manager </dev/tty; then
                    hash -r
                    log::ok "YubiKey Manager removed"
                else
                    log::error "Failed to remove YubiKey Manager"
                fi
                ;;
        esac
    done
}
