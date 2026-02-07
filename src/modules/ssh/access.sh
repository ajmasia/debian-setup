# SSH access mode configuration task

[[ -n "${_MOD_SSH_ACCESS_LOADED:-}" ]] && return 0
_MOD_SSH_ACCESS_LOADED=1

_SSH_ACCESS_LABEL="Configure SSH access"
_SSH_ACCESS_DESC="Set SSH access mode: pubkey-only, pubkey+password, or password-only."

# Returns: "pubkey-only", "password-only", "pubkey+password"
_ssh_access::mode() {
    local pubkey=true password=true

    grep -q '^PubkeyAuthentication no' "$_SSH_SSHD_CONFIG" 2>/dev/null && pubkey=false
    grep -q '^PasswordAuthentication no' "$_SSH_SSHD_CONFIG" 2>/dev/null && password=false

    if $pubkey && ! $password; then
        printf '%s' "pubkey-only"
    elif ! $pubkey && $password; then
        printf '%s' "password-only"
    else
        printf '%s' "pubkey+password"
    fi
}

_ssh_access::root_allowed() {
    ! grep -q '^PermitRootLogin no' "$_SSH_SSHD_CONFIG" 2>/dev/null
}

ssh_access::check() {
    _ssh_server::installed && [[ "$(_ssh_access::mode)" == "pubkey-only" ]]
}

ssh_access::status() {
    if ! _ssh_server::installed; then
        printf '%s' "server not installed"
    else
        printf '%s' "$(_ssh_access::mode)"
    fi
}

ssh_access::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "SSH > Configure SSH access"
        log::break

        if ! _ssh_server::installed; then
            log::warn "SSH server is not installed"
            log::info "Install the SSH server first to configure access"
            ui::return_or_exit
            return
        fi

        local mode
        mode="$(_ssh_access::mode)"

        log::info "Current access mode"

        local root_allowed=false
        _ssh_access::root_allowed && root_allowed=true

        case "$mode" in
            "pubkey-only")
                log::ok "Access: pubkey-only (no password fallback)"
                ;;
            "password-only")
                log::warn "Access: password-only (no pubkey)"
                ;;
            "pubkey+password")
                log::ok "Access: pubkey + password (key first, password fallback)"
                ;;
        esac

        if $root_allowed; then
            log::warn "Root login: enabled"
        else
            log::ok "Root login: disabled"
        fi

        log::break

        local options=()
        [[ "$mode" != "pubkey-only" ]] && options+=("Pubkey-only")
        [[ "$mode" != "pubkey+password" ]] && options+=("Pubkey + password")
        [[ "$mode" != "password-only" ]] && options+=("Password-only")
        if $root_allowed; then
            options+=("Disable root login")
        else
            options+=("Enable root login")
        fi
        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Switch access mode to:" \
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
            "Pubkey-only")
                log::break
                log::info "Switching to pubkey-only access"
                ui::flush_input
                _ssh_server::_sed_config "PubkeyAuthentication" "PubkeyAuthentication yes"
                _ssh_server::_sed_config "PasswordAuthentication" "PasswordAuthentication no"
                _ssh_server::_sed_config "KbdInteractiveAuthentication" "KbdInteractiveAuthentication no"
                log::ok "Access mode: pubkey-only"
                _ssh_access::_restart
                ;;
            "Pubkey + password")
                log::break
                log::info "Switching to pubkey + password access"
                ui::flush_input
                _ssh_server::_sed_config "PubkeyAuthentication" "PubkeyAuthentication yes"
                _ssh_server::_sed_config "PasswordAuthentication" "PasswordAuthentication yes"
                _ssh_server::_sed_config "KbdInteractiveAuthentication" "KbdInteractiveAuthentication yes"
                log::ok "Access mode: pubkey + password"
                _ssh_access::_restart
                ;;
            "Password-only")
                log::break
                log::info "Switching to password-only access"
                ui::flush_input
                _ssh_server::_sed_config "PubkeyAuthentication" "PubkeyAuthentication no"
                _ssh_server::_sed_config "PasswordAuthentication" "PasswordAuthentication yes"
                _ssh_server::_sed_config "KbdInteractiveAuthentication" "KbdInteractiveAuthentication yes"
                log::ok "Access mode: password-only"
                _ssh_access::_restart
                ;;
            "Disable root login")
                log::break
                log::info "Disabling root login"
                ui::flush_input
                _ssh_server::_sed_config "PermitRootLogin" "PermitRootLogin no"
                log::ok "Root login disabled"
                _ssh_access::_restart
                ;;
            "Enable root login")
                log::break
                log::info "Enabling root login"
                ui::flush_input
                _ssh_server::_sed_config "PermitRootLogin" "PermitRootLogin yes"
                log::ok "Root login enabled"
                _ssh_access::_restart
                ;;
        esac
    done
}

_ssh_access::_restart() {
    log::info "Restarting ssh service"
    if sudo systemctl restart ssh </dev/tty; then
        log::ok "ssh service restarted"
    else
        log::error "Failed to restart ssh service"
    fi
}
