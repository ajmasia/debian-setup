# HTTPie task

[[ -n "${_MOD_HTTPIE_LOADED:-}" ]] && return 0
_MOD_HTTPIE_LOADED=1

_HTTPIE_LABEL="Configure HTTPie"
_HTTPIE_DESC="Install or remove HTTPie (modern HTTP client)."

_httpie::is_installed() {
    dpkg -l httpie 2>/dev/null | grep -q '^ii'
}

httpie::check() {
    _httpie::is_installed
}

httpie::status() {
    _httpie::is_installed || printf 'not installed'
}

httpie::apply() {
    local choice

    while true; do
        local installed=false
        _httpie::is_installed && installed=true

        ui::clear_content
        log::nav "Development > Tools > HTTPie"
        log::break

        log::info "HTTPie"

        if $installed; then
            local version
            version="$(http --version 2>/dev/null || true)"
            log::ok "HTTPie: ${version}"
        else
            log::warn "HTTPie (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove HTTPie")
        else
            options+=("Install HTTPie")
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
            "Install HTTPie")
                log::break
                log::info "Installing HTTPie"
                ui::flush_input
                if sudo apt-get install -y httpie </dev/tty; then
                    hash -r
                    log::ok "HTTPie installed"
                else
                    log::error "Failed to install HTTPie"
                fi
                ;;
            "Remove HTTPie")
                log::break
                log::info "Removing HTTPie"
                ui::flush_input
                if sudo apt-get remove -y httpie </dev/tty; then
                    hash -r
                    log::ok "HTTPie removed"
                else
                    log::error "Failed to remove HTTPie"
                fi
                ;;
        esac
    done
}
