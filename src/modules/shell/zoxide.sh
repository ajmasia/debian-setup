# Zoxide smart cd shell tool task

[[ -n "${_MOD_ZOXIDE_LOADED:-}" ]] && return 0
_MOD_ZOXIDE_LOADED=1

_ZOXIDE_LABEL="Configure Zoxide"
_ZOXIDE_DESC="Install or remove Zoxide smart directory jumper."

_ZOXIDE_INSTALL_URL="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
_ZOXIDE_BIN="$HOME/.local/bin/zoxide"
_ZOXIDE_BASHRC_MARKER="# Added by debian-setup: zoxide"
_ZOXIDE_BASHRC_LINE='eval "$(zoxide init bash)"'

_zoxide::is_installed() {
    [[ -x "$_ZOXIDE_BIN" ]]
}

_zoxide::session_ready() {
    command -v zoxide &>/dev/null
}

zoxide::check() {
    _zoxide::is_installed && _zoxide::session_ready
}

zoxide::status() {
    local issues=()
    _zoxide::is_installed || issues+=("not installed")
    _zoxide::is_installed && ! _zoxide::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

zoxide::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _zoxide::is_installed && installed=true
        _zoxide::session_ready && session_ready=true

        ui::clear_content
        log::nav "Shell > Zoxide"
        log::break

        log::info "Zoxide"

        if $installed; then
            if $session_ready; then
                local version
                version="$(zoxide --version 2>/dev/null || true)"
                log::ok "Zoxide: ${version}"
            else
                log::ok "Zoxide: installed"
                log::warn "Restart needed to activate zoxide in current session"
            fi
        else
            log::warn "Zoxide (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Zoxide" "Remove Zoxide")
        else
            options+=("Install Zoxide")
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
            "Install Zoxide"|"Update Zoxide")
                log::break
                _zoxide::install
                ;;
            "Remove Zoxide")
                log::break
                _zoxide::remove
                ;;
        esac
    done
}

_zoxide::install() {
    log::info "Installing Zoxide"

    mkdir -p "$HOME/.local/bin"

    if ! curl -sSfL "$_ZOXIDE_INSTALL_URL" | sh; then
        log::error "Failed to install Zoxide"
        return
    fi

    hash -r
    log::ok "Zoxide installed"

    # Add to .bashrc if not already present
    if [[ -f "$HOME/.bashrc" ]] && grep -Fq 'zoxide init bash' "$HOME/.bashrc"; then
        log::ok "bashrc already configured"
    else
        printf '\n%s\n%s\n' "$_ZOXIDE_BASHRC_MARKER" "$_ZOXIDE_BASHRC_LINE" >> "$HOME/.bashrc"
        log::ok "Added zoxide init to .bashrc"
    fi

    # PATH warning
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    log::break
    log::warn "Restart your shell to activate Zoxide"
}

_zoxide::remove() {
    log::info "Removing Zoxide"

    rm -f "$_ZOXIDE_BIN"
    log::ok "Binary removed"

    # Clean .bashrc
    if [[ -f "$HOME/.bashrc" ]]; then
        local tmp
        tmp="$(mktemp)"
        grep -v 'zoxide init bash' "$HOME/.bashrc" | grep -v 'debian-setup: zoxide' > "$tmp" || true
        mv "$tmp" "$HOME/.bashrc"
        log::ok "Cleaned .bashrc"
    fi

    hash -r
    log::ok "Zoxide removed"
    log::break
    log::warn "Restart your shell to complete cleanup"
}
