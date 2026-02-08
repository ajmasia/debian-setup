# Rust (rustup) developer tool task

[[ -n "${_MOD_RUST_LOADED:-}" ]] && return 0
_MOD_RUST_LOADED=1

_RUST_LABEL="Configure Rust"
_RUST_DESC="Install or remove Rust via rustup (rustc, cargo, rustup)."

_RUST_INSTALL_URL="https://sh.rustup.rs"
_RUST_CARGO_DIR="${HOME}/.cargo"

_rust::is_installed() {
    [[ -f "${_RUST_CARGO_DIR}/bin/cargo" ]]
}

_rust::session_ready() {
    command -v cargo &>/dev/null
}

rust::check() {
    _rust::is_installed && _rust::session_ready
}

rust::status() {
    local issues=()
    _rust::is_installed || issues+=("not installed")
    _rust::is_installed && ! _rust::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

rust::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _rust::is_installed && installed=true
        _rust::session_ready && session_ready=true

        ui::clear_content
        log::nav "Development > Environments > Rust"
        log::break

        log::info "Current Rust configuration"

        if $installed; then
            if $session_ready; then
                local rustup_ver rustc_ver cargo_ver
                rustup_ver="$(rustup --version 2>/dev/null || true)"
                rustc_ver="$(rustc --version 2>/dev/null || true)"
                cargo_ver="$(cargo --version 2>/dev/null || true)"
                log::ok "rustup: ${rustup_ver}"
                log::ok "rustc: ${rustc_ver}"
                log::ok "cargo: ${cargo_ver}"
            else
                log::ok "Rust: installed"
                log::warn "Restart needed to activate Rust in current session"
            fi
        else
            log::warn "Rust: not installed"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            options+=("Remove Rust")
        else
            options+=("Install Rust")
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
            "Install Rust")
                log::break
                log::info "Installing Rust via rustup"
                log::break
                ui::flush_input
                if curl --proto '=https' --tlsv1.2 -sSf "$_RUST_INSTALL_URL" | sh -s -- -y; then
                    hash -r
                    log::break
                    log::ok "Rust installed"
                    log::break
                    log::warn "Restart your shell or run: source \$HOME/.cargo/env"
                else
                    log::break
                    log::error "Rust installation failed"
                fi
                ;;
            "Remove Rust")
                log::break
                log::info "Removing Rust via rustup"
                ui::flush_input
                if "${_RUST_CARGO_DIR}/bin/rustup" self uninstall -y </dev/tty; then
                    hash -r
                    log::ok "Rust removed"
                    log::break
                    log::warn "Restart your shell to complete cleanup"
                else
                    log::error "Failed to remove Rust"
                fi
                ;;
        esac
    done
}
