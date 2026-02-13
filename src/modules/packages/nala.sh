# Nala APT frontend task

[[ -n "${_MOD_NALA_LOADED:-}" ]] && return 0
_MOD_NALA_LOADED=1

_NALA_LABEL="Configure Nala"
_NALA_DESC="Install or remove Nala, a prettier frontend for APT
with parallel downloads and a cleaner interface."

_nala::is_installed() {
    command -v nala &>/dev/null
}

nala::check() {
    _nala::is_installed
}

nala::status() {
    _nala::is_installed || printf 'not installed'
}

nala::apply() {
    local choice

    while true; do
        local installed=false
        _nala::is_installed && installed=true

        ui::clear_content
        log::nav "Package managers > Configure Nala"
        log::break

        log::info "Current Nala configuration"

        if $installed; then
            local version
            version="$(nala --version 2>/dev/null || true)"
            log::ok "Nala: installed (${version})"
        else
            log::warn "Nala: not installed"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Nala")
        else
            options+=("Install Nala")
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
            "Install Nala")
                log::break
                log::info "Installing Nala"
                ui::flush_input
                if sudo apt-get install -y nala </dev/tty; then
                    hash -r
                    log::ok "Nala installed"
                else
                    log::error "Failed to install Nala"
                fi
                ;;
            "Remove Nala")
                log::break
                log::info "Removing Nala"
                ui::flush_input
                if sudo apt-get remove -y nala </dev/tty; then
                    hash -r
                    log::ok "Nala removed"
                else
                    log::error "Failed to remove Nala"
                fi
                ;;
        esac
    done
}
