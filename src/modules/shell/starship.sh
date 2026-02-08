# Starship prompt shell tool task

[[ -n "${_MOD_STARSHIP_LOADED:-}" ]] && return 0
_MOD_STARSHIP_LOADED=1

_STARSHIP_LABEL="Configure Starship"
_STARSHIP_DESC="Install or remove Starship cross-shell prompt."

_STARSHIP_INSTALL_URL="https://starship.rs/install.sh"
_STARSHIP_BIN="$HOME/.local/bin/starship"
_STARSHIP_BASHRC_MARKER="# Added by debian-setup: starship"
_STARSHIP_BASHRC_LINE='eval "$(starship init bash)"'

_starship::is_installed() {
    [[ -x "$_STARSHIP_BIN" ]]
}

_starship::session_ready() {
    command -v starship &>/dev/null
}

starship::check() {
    _starship::is_installed && _starship::session_ready
}

starship::status() {
    local issues=()
    _starship::is_installed || issues+=("not installed")
    _starship::is_installed && ! _starship::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

starship::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _starship::is_installed && installed=true
        _starship::session_ready && session_ready=true

        ui::clear_content
        log::nav "Shell > Starship"
        log::break

        log::info "Starship"

        if $installed; then
            if $session_ready; then
                local version
                version="$(starship --version 2>/dev/null | head -1 || true)"
                log::ok "Starship: ${version}"
            else
                log::ok "Starship: installed"
                log::warn "Restart needed to activate starship in current session"
            fi
        else
            log::warn "Starship (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Starship" "Remove Starship")
        else
            options+=("Install Starship")
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
            "Install Starship"|"Update Starship")
                log::break
                _starship::install
                ;;
            "Remove Starship")
                log::break
                _starship::remove
                ;;
        esac
    done
}

_starship::install() {
    log::info "Installing Starship"

    mkdir -p "$HOME/.local/bin"

    if ! curl -sS "$_STARSHIP_INSTALL_URL" | sh -s -- -y -b "$HOME/.local/bin"; then
        log::error "Failed to install Starship"
        return
    fi

    hash -r
    log::ok "Starship installed"

    # Add to .bashrc if not already present
    if [[ -f "$HOME/.bashrc" ]] && grep -Fq 'starship init bash' "$HOME/.bashrc"; then
        log::ok "bashrc already configured"
    else
        printf '\n%s\n%s\n' "$_STARSHIP_BASHRC_MARKER" "$_STARSHIP_BASHRC_LINE" >> "$HOME/.bashrc"
        log::ok "Added starship init to .bashrc"
    fi

    # PATH warning
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    log::break
    log::warn "Restart your shell to activate Starship"
}

_starship::remove() {
    log::info "Removing Starship"

    rm -f "$_STARSHIP_BIN"
    log::ok "Binary removed"

    # Clean .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        local tmp
        tmp="$(mktemp)"
        grep -v 'starship init bash' "$HOME/.bashrc" | grep -v 'debian-setup: starship' > "$tmp" || true
        mv "$tmp" "$HOME/.bashrc"
        log::ok "Cleaned .bashrc"
    fi

    hash -r
    log::ok "Starship removed"
    log::break
    log::warn "Restart your shell to complete cleanup"
}
