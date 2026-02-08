# Python (uv) developer tool task

[[ -n "${_MOD_PYTHON_LOADED:-}" ]] && return 0
_MOD_PYTHON_LOADED=1

_PYTHON_LABEL="Configure Python"
_PYTHON_DESC="Install or remove uv (fast Python package manager)."

_PYTHON_UV_INSTALL_URL="https://astral.sh/uv/install.sh"

_python::is_installed() {
    [[ -f "$HOME/.local/bin/uv" ]]
}

_python::session_ready() {
    command -v uv &>/dev/null
}

python::check() {
    _python::is_installed && _python::session_ready
}

python::status() {
    local issues=()
    _python::is_installed || issues+=("not installed")
    _python::is_installed && ! _python::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

python::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _python::is_installed && installed=true
        _python::session_ready && session_ready=true

        ui::clear_content
        log::nav "Development > Environments > Python"
        log::break

        log::info "Current Python (uv) configuration"

        if $installed; then
            if $session_ready; then
                local version
                version="$(uv --version 2>/dev/null || true)"
                log::ok "uv: installed (${version})"
            else
                log::ok "uv: installed"
                log::warn "Restart needed to activate uv in current session"
            fi
        else
            log::warn "uv: not installed"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            options+=("Remove uv")
        else
            options+=("Install uv")
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
            "Install uv")
                log::break
                log::info "Installing uv (Python package manager)"
                log::break
                ui::flush_input
                if curl -LsSf "$_PYTHON_UV_INSTALL_URL" | sh; then
                    hash -r
                    log::break
                    log::ok "uv installed"
                    log::break
                    log::warn "Restart your shell or run: source \$HOME/.local/bin/env"
                else
                    log::break
                    log::error "uv installation failed"
                fi
                ;;
            "Remove uv")
                log::break
                log::info "Removing uv"
                rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
                hash -r
                log::ok "uv removed"
                log::break
                log::warn "Restart your shell to complete cleanup"
                ;;
        esac
    done
}
