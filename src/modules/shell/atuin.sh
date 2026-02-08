# Atuin shell history tool task

[[ -n "${_MOD_ATUIN_LOADED:-}" ]] && return 0
_MOD_ATUIN_LOADED=1

_ATUIN_LABEL="Configure Atuin"
_ATUIN_DESC="Install or remove Atuin shell history manager."

_ATUIN_INSTALL_URL="https://setup.atuin.sh"
_ATUIN_BIN="$HOME/.atuin/bin/atuin"

_atuin::is_installed() {
    [[ -x "$_ATUIN_BIN" ]]
}

_atuin::session_ready() {
    command -v atuin &>/dev/null
}

atuin::check() {
    _atuin::is_installed && _atuin::session_ready
}

atuin::status() {
    local issues=()
    _atuin::is_installed || issues+=("not installed")
    _atuin::is_installed && ! _atuin::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

atuin::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _atuin::is_installed && installed=true
        _atuin::session_ready && session_ready=true

        ui::clear_content
        log::nav "Shell > Atuin"
        log::break

        log::info "Atuin"

        if $installed; then
            if $session_ready; then
                local version
                version="$(atuin --version 2>/dev/null || true)"
                log::ok "Atuin: ${version}"
            else
                log::ok "Atuin: installed"
                log::warn "Restart needed to activate atuin in current session"
            fi
        else
            log::warn "Atuin (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Atuin" "Remove Atuin")
        else
            options+=("Install Atuin")
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
            "Install Atuin"|"Update Atuin")
                log::break
                _atuin::install
                ;;
            "Remove Atuin")
                log::break
                _atuin::remove
                ;;
        esac
    done
}

_atuin::install() {
    log::info "Installing Atuin"

    if ! curl --proto '=https' --tlsv1.2 -LsSf "$_ATUIN_INSTALL_URL" | sh; then
        log::error "Failed to install Atuin"
        return
    fi

    hash -r
    log::ok "Atuin installed"

    # The atuin installer auto-configures .bashrc, verify it was added
    if [[ -f "$HOME/.bashrc" ]] && grep -Fq 'atuin init bash' "$HOME/.bashrc"; then
        log::ok "bashrc already configured by installer"
    else
        log::warn "Atuin init not found in .bashrc — you may need to configure it manually"
    fi

    log::break
    log::warn "Restart your shell to activate Atuin"
}

_atuin::remove() {
    log::info "Removing Atuin"

    rm -rf "$HOME/.atuin"
    log::ok "Atuin directory removed"

    # Clean .bashrc (remove all atuin-related lines)
    if [[ -f "$HOME/.bashrc" ]]; then
        local tmp
        tmp="$(mktemp)"
        grep -v 'atuin' "$HOME/.bashrc" > "$tmp" || true
        mv "$tmp" "$HOME/.bashrc"
        log::ok "Cleaned .bashrc"
    fi

    hash -r
    log::ok "Atuin removed"
    log::break
    log::warn "Restart your shell to complete cleanup"
}
