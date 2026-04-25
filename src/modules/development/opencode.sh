# OpenCode task

[[ -n "${_MOD_OPENCODE_LOADED:-}" ]] && return 0
_MOD_OPENCODE_LOADED=1

_OPENCODE_LABEL="Configure OpenCode"
_OPENCODE_DESC="Install or remove OpenCode (npm global)."

_opencode::is_installed() {
    command -v opencode &>/dev/null
}

opencode::check() {
    _opencode::is_installed
}

opencode::status() {
    _opencode::is_installed || printf 'not installed'
}

opencode::apply() {
    local choice

    while true; do
        local installed=false
        _opencode::is_installed && installed=true

        ui::clear_content
        log::nav "Development > AI > OpenCode"
        log::break

        log::info "OpenCode"

        if $installed; then
            local version
            version="$(opencode --version 2>/dev/null || true)"
            log::ok "OpenCode: ${version}"
        else
            log::warn "OpenCode (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove OpenCode")
        else
            options+=("Install OpenCode")
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
            "Install OpenCode")
                log::break
                _opencode::install
                ;;
            "Remove OpenCode")
                log::break
                _opencode::remove
                ;;
        esac
    done
}

_opencode::install() {
    if ! command -v npm &>/dev/null; then
        log::error "npm not available. Install Node.js first (Development > Environments > Node.js)"
        ui::return_or_exit
        return
    fi

    log::info "Installing OpenCode"
    if npm install -g opencode-ai@latest; then
        hash -r
        log::ok "OpenCode installed"
    else
        log::error "Failed to install OpenCode"
    fi
    ui::return_or_exit
}

_opencode::remove() {
    log::info "Removing OpenCode"
    if npm uninstall -g opencode-ai; then
        hash -r
        log::ok "OpenCode removed"
    else
        log::error "Failed to remove OpenCode"
    fi
    ui::return_or_exit
}
