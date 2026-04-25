# Proton Pass CLI task

[[ -n "${_MOD_PASSCLI_LOADED:-}" ]] && return 0
_MOD_PASSCLI_LOADED=1

_PASSCLI_LABEL="Configure Proton Pass CLI"
_PASSCLI_DESC="Install Proton Pass CLI."
_PASSCLI_INSTALL_URL="https://proton.me/download/PassDesktop/linux/x64/ProtonPassCLI"
_PASSCLI_BIN="$HOME/.local/bin/proton-pass-cli"

_passcli::is_installed() {
    [[ -x "$_PASSCLI_BIN" ]]
}

_passcli::session_ready() {
    command -v proton-pass-cli &>/dev/null
}

passcli::check() {
    _passcli::is_installed && _passcli::session_ready
}

passcli::status() {
    local issues=()
    _passcli::is_installed || issues+=("not installed")
    _passcli::is_installed && ! _passcli::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

passcli::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _passcli::is_installed && installed=true
        _passcli::session_ready && session_ready=true

        ui::clear_content
        log::nav "Software > Security > Password Managers > Proton Pass CLI"
        log::break

        log::info "Proton Pass CLI"

        if $installed; then
            if $session_ready; then
                local version
                version="$(proton-pass-cli --version 2>/dev/null || true)"
                log::ok "Proton Pass CLI: ${version}"
            else
                log::ok "Proton Pass CLI: installed"
                log::warn "Restart needed to activate in current session"
            fi
        else
            log::warn "Proton Pass CLI (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Proton Pass CLI" "Remove Proton Pass CLI")
        else
            options+=("Install Proton Pass CLI")
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
            "Install Proton Pass CLI"|"Update Proton Pass CLI")
                log::break
                _passcli::install
                ;;
            "Remove Proton Pass CLI")
                log::break
                _passcli::remove
                ;;
        esac
    done
}

_passcli::install() {
    log::info "Downloading Proton Pass CLI"

    mkdir -p "$HOME/.local/bin"

    if ! curl -fsSLo "$_PASSCLI_BIN" "$_PASSCLI_INSTALL_URL"; then
        log::error "Failed to download Proton Pass CLI"
        ui::return_or_exit
        return
    fi

    chmod +x "$_PASSCLI_BIN"
    hash -r

    log::ok "Proton Pass CLI installed"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
    ui::return_or_exit
}

_passcli::remove() {
    log::info "Removing Proton Pass CLI"

    rm -f "$_PASSCLI_BIN"
    hash -r

    log::ok "Proton Pass CLI removed"
    ui::return_or_exit
}
