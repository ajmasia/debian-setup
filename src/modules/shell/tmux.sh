# Tmux terminal multiplexer task

[[ -n "${_MOD_TMUX_LOADED:-}" ]] && return 0
_MOD_TMUX_LOADED=1

_TMUX_LABEL="Configure Tmux"
_TMUX_DESC="Install or remove Tmux terminal multiplexer."

_tmux::is_installed() {
    dpkg -l tmux 2>/dev/null | grep -q '^ii'
}

tmux::check() {
    _tmux::is_installed
}

tmux::status() {
    _tmux::is_installed || printf 'not installed'
}

tmux::apply() {
    local choice

    while true; do
        local installed=false
        _tmux::is_installed && installed=true

        ui::clear_content
        log::nav "Shell > Tmux"
        log::break

        log::info "Tmux"

        if $installed; then
            local version
            version="$(dpkg -l tmux 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Tmux ${version}"
        else
            log::warn "Tmux (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Tmux")
        else
            options+=("Install Tmux")
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
            "Install Tmux")
                log::break
                log::info "Installing Tmux"
                ui::flush_input
                if sudo apt-get install -y tmux </dev/tty; then
                    hash -r
                    log::ok "Tmux installed"
                else
                    log::error "Failed to install Tmux"
                fi
                ;;
            "Remove Tmux")
                log::break
                log::info "Removing Tmux"
                ui::flush_input
                if sudo apt-get remove -y tmux </dev/tty; then
                    hash -r
                    log::ok "Tmux removed"
                else
                    log::error "Failed to remove Tmux"
                fi
                ;;
        esac
    done
}
