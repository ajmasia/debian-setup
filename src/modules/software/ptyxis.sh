# Ptyxis terminal emulator task

[[ -n "${_MOD_PTYXIS_LOADED:-}" ]] && return 0
_MOD_PTYXIS_LOADED=1

_PTYXIS_LABEL="Configure Ptyxis"
_PTYXIS_DESC="Install Ptyxis terminal emulator."

_ptyxis::is_installed() {
    dpkg -l ptyxis 2>/dev/null | grep -q '^ii'
}

ptyxis::check() {
    _ptyxis::is_installed
}

ptyxis::status() {
    _ptyxis::is_installed || printf 'not installed'
}

ptyxis::apply() {
    local choice

    while true; do
        local installed=false
        _ptyxis::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Terminals > Ptyxis"
        log::break

        log::info "Ptyxis"

        if $installed; then
            local version
            version="$(dpkg -l ptyxis 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Ptyxis ${version}"
        else
            log::warn "Ptyxis (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Ptyxis")
        else
            options+=("Install Ptyxis")
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
            "Install Ptyxis")
                log::break
                log::info "Installing Ptyxis"
                ui::flush_input
                if sudo apt-get install -y ptyxis </dev/tty; then
                    hash -r
                    log::ok "Ptyxis installed"
                else
                    log::error "Failed to install Ptyxis"
                fi
                ;;
            "Remove Ptyxis")
                log::break
                log::info "Removing Ptyxis"
                ui::flush_input
                if sudo apt-get remove -y ptyxis </dev/tty; then
                    hash -r
                    log::ok "Ptyxis removed"
                else
                    log::error "Failed to remove Ptyxis"
                fi
                ;;
        esac
    done
}
