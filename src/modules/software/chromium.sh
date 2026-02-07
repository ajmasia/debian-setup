# Chromium browser task

[[ -n "${_MOD_CHROMIUM_LOADED:-}" ]] && return 0
_MOD_CHROMIUM_LOADED=1

_CHROMIUM_LABEL="Configure Chromium"
_CHROMIUM_DESC="Install Chromium browser."

_chromium::is_installed() {
    dpkg -l chromium 2>/dev/null | grep -q '^ii'
}

chromium::check() {
    _chromium::is_installed
}

chromium::status() {
    _chromium::is_installed || printf 'not installed'
}

chromium::apply() {
    local choice

    while true; do
        local installed=false
        _chromium::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Browsers > Chromium"
        log::break

        log::info "Chromium"

        if $installed; then
            local version
            version="$(dpkg -l chromium 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Chromium ${version}"
        else
            log::warn "Chromium (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Chromium")
        else
            options+=("Install Chromium")
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
            "Install Chromium")
                log::break
                log::info "Installing Chromium"
                ui::flush_input
                if sudo apt-get install -y chromium </dev/tty; then
                    hash -r
                    log::ok "Chromium installed"
                else
                    log::error "Failed to install Chromium"
                fi
                ;;
            "Remove Chromium")
                log::break
                log::info "Removing Chromium"
                ui::flush_input
                if sudo apt-get remove -y chromium </dev/tty; then
                    hash -r
                    log::ok "Chromium removed"
                else
                    log::error "Failed to remove Chromium"
                fi
                ;;
        esac
    done
}
