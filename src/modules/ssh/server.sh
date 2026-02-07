# SSH server configuration task

[[ -n "${_MOD_SSH_SERVER_LOADED:-}" ]] && return 0
_MOD_SSH_SERVER_LOADED=1

_SSH_SERVER_LABEL="Configure OpenSSH server"
_SSH_SERVER_DESC="Install and manage OpenSSH server service."

_SSH_SSHD_CONFIG="/etc/ssh/sshd_config"

_ssh_server::installed() {
    dpkg -l openssh-server 2>/dev/null | grep -q '^ii'
}

_ssh_server::enabled() {
    systemctl is-enabled ssh &>/dev/null
}

_ssh_server::running() {
    systemctl is-active ssh &>/dev/null
}

ssh_server::check() {
    _ssh_server::installed && _ssh_server::enabled && _ssh_server::running
}

ssh_server::status() {
    local issues=()
    _ssh_server::installed || issues+=("not installed")
    _ssh_server::installed && ! _ssh_server::enabled && issues+=("not enabled")
    _ssh_server::installed && _ssh_server::enabled && ! _ssh_server::running && issues+=("not running")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

ssh_server::apply() {
    local choice

    while true; do
        local installed=false enabled=false running=false
        _ssh_server::installed && installed=true
        _ssh_server::enabled && enabled=true
        _ssh_server::running && running=true

        ui::clear_content
        log::nav "OpenSSH server > Configure OpenSSH server"
        log::break

        log::info "Current SSH server configuration"

        if $installed; then
            log::ok "openssh-server: installed"
        else
            log::warn "openssh-server: not installed"
        fi

        if $installed; then
            if $enabled; then
                log::ok "ssh service: enabled"
            else
                log::warn "ssh service: not enabled"
            fi

            if $running; then
                log::ok "ssh service: running"
            else
                log::warn "ssh service: not running"
            fi
        fi

        log::break

        local options=()
        if ! $installed; then
            options+=("Install SSH server")
        else
            if ! $enabled; then
                options+=("Enable ssh service")
            fi
            if ! $running; then
                options+=("Start ssh service")
            fi
            if $running; then
                options+=("Stop ssh service")
            fi
            if $enabled; then
                options+=("Disable ssh service")
            fi
            options+=("Remove openssh-server")
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
            "Install SSH server")
                log::break
                log::info "Installing openssh-server"
                ui::flush_input
                if sudo apt install -y openssh-server </dev/tty; then
                    hash -r
                    log::ok "openssh-server installed"
                else
                    log::error "Failed to install openssh-server"
                    continue
                fi

                log::info "Enabling and starting ssh service"
                ui::flush_input
                if sudo systemctl enable --now ssh </dev/tty; then
                    log::ok "ssh service enabled and started"
                else
                    log::error "Failed to enable ssh service"
                fi

                # Default: pubkey-only, no root login
                log::info "Applying default access: pubkey-only, no root login"
                _ssh_server::_sed_config "PermitRootLogin" "PermitRootLogin no"
                _ssh_server::_sed_config "PubkeyAuthentication" "PubkeyAuthentication yes"
                _ssh_server::_sed_config "PasswordAuthentication" "PasswordAuthentication no"
                _ssh_server::_sed_config "KbdInteractiveAuthentication" "KbdInteractiveAuthentication no"
                log::ok "Default access configured"
                if sudo systemctl restart ssh </dev/tty; then
                    log::ok "ssh service restarted"
                fi
                ;;
            "Enable ssh service")
                log::break
                log::info "Enabling ssh service"
                ui::flush_input
                if sudo systemctl enable ssh </dev/tty; then
                    log::ok "ssh service enabled"
                else
                    log::error "Failed to enable ssh service"
                fi
                ;;
            "Start ssh service")
                log::break
                log::info "Starting ssh service"
                ui::flush_input
                if sudo systemctl start ssh </dev/tty; then
                    log::ok "ssh service started"
                else
                    log::error "Failed to start ssh service"
                fi
                ;;
            "Stop ssh service")
                log::break
                log::info "Stopping ssh service"
                ui::flush_input
                if sudo systemctl stop ssh </dev/tty; then
                    log::ok "ssh service stopped"
                else
                    log::error "Failed to stop ssh service"
                fi
                ;;
            "Disable ssh service")
                log::break
                log::info "Disabling ssh service"
                ui::flush_input
                if sudo systemctl disable ssh </dev/tty; then
                    log::ok "ssh service disabled"
                else
                    log::error "Failed to disable ssh service"
                fi
                ;;
            "Remove openssh-server")
                log::break
                log::info "Removing openssh-server"
                ui::flush_input
                if sudo apt remove -y openssh-server </dev/tty; then
                    hash -r
                    log::ok "openssh-server removed"
                else
                    log::error "Failed to remove openssh-server"
                    continue
                fi

                _ssh_server::_cleanup_prompt
                return
                ;;
        esac
    done
}

_ssh_server::_cleanup_prompt() {
    local items=()

    [[ -f "$HOME/.ssh/authorized_keys" ]] && items+=("authorized_keys")
    compgen -G "$HOME/.ssh/id_*" &>/dev/null && items+=("SSH keys (id_*)")
    [[ -f "$HOME/.ssh/allowed_signers" ]] && items+=("allowed_signers")

    if [[ ${#items[@]} -eq 0 ]]; then
        return
    fi

    log::break
    log::info "Also remove SSH user files?"
    ui::flush_input

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select files to remove (space to select):" \
        "${items[@]}")"

    [[ -z "$selected" ]] && return

    local line
    while IFS= read -r line; do
        case "$line" in
            "authorized_keys")
                rm -f "$HOME/.ssh/authorized_keys"
                log::ok "Removed ~/.ssh/authorized_keys"
                ;;
            "SSH keys (id_*)")
                rm -f "$HOME"/.ssh/id_*
                log::ok "Removed SSH keys (~/.ssh/id_*)"
                ;;
            "allowed_signers")
                rm -f "$HOME/.ssh/allowed_signers"
                git config --global --unset gpg.ssh.allowedSignersFile || true
                log::ok "Removed ~/.ssh/allowed_signers"
                ;;
        esac
    done <<< "$selected"
}

# Shared helper: edit sshd_config directives (used by server.sh and access.sh)
_ssh_server::_sed_config() {
    local pattern="$1"
    local replacement="$2"

    if grep -q "^${pattern}" "$_SSH_SSHD_CONFIG" 2>/dev/null; then
        sudo sed -i "s/^${pattern}.*/${replacement}/" "$_SSH_SSHD_CONFIG" </dev/tty
    elif grep -q "^#.*${pattern}" "$_SSH_SSHD_CONFIG" 2>/dev/null; then
        sudo sed -i "s/^#.*${pattern}.*/${replacement}/" "$_SSH_SSHD_CONFIG" </dev/tty
    fi
}
