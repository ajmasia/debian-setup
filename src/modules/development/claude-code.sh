# Claude Code task

[[ -n "${_MOD_CLAUDECODE_LOADED:-}" ]] && return 0
_MOD_CLAUDECODE_LOADED=1

_CLAUDECODE_LABEL="Configure Claude Code"
_CLAUDECODE_DESC="Install or remove Claude Code (native installer)."

_claudecode::is_installed() {
    command -v claude &>/dev/null
}

claudecode::check() {
    _claudecode::is_installed
}

claudecode::status() {
    _claudecode::is_installed || printf 'not installed'
}

claudecode::apply() {
    local choice

    while true; do
        local installed=false
        _claudecode::is_installed && installed=true

        ui::clear_content
        log::nav "Development > AI > Claude Code"
        log::break

        log::info "Claude Code"

        if $installed; then
            local version
            version="$(claude --version 2>/dev/null || true)"
            log::ok "Claude Code: ${version}"
        else
            log::warn "Claude Code (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Claude Code")
        else
            options+=("Install Claude Code")
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
            "Install Claude Code")
                log::break
                _claudecode::install
                ;;
            "Remove Claude Code")
                log::break
                _claudecode::remove
                ;;
        esac
    done
}

_claudecode::install() {
    if ! command -v curl &>/dev/null; then
        log::error "curl is required but not installed"
        return
    fi

    log::info "Installing Claude Code (native installer)"
    if curl -fsSL https://claude.ai/install.sh | bash; then
        hash -r
        log::ok "Claude Code installed"
    else
        log::error "Failed to install Claude Code"
    fi
}

_claudecode::remove() {
    log::info "Removing Claude Code"
    rm -f "${HOME}/.local/bin/claude"
    rm -rf "${HOME}/.local/share/claude"
    hash -r
    log::ok "Claude Code removed"
}
