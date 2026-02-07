# Nix package manager task

[[ -n "${_MOD_NIX_LOADED:-}" ]] && return 0
_MOD_NIX_LOADED=1

_NIX_LABEL="Configure Nix"
_NIX_DESC="Install or remove the Nix package manager (multi-user daemon mode)."

_NIX_INSTALL_URL="https://nixos.org/nix/install"

_nix::is_installed() {
    [[ -d /nix/store ]]
}

_nix::session_ready() {
    command -v nix &>/dev/null
}

_nix::daemon_active() {
    systemctl is-active nix-daemon.socket &>/dev/null \
        || systemctl is-active nix-daemon.service &>/dev/null
}

_nix::flakes_enabled() {
    grep -q 'flakes' /etc/nix/nix.conf 2>/dev/null
}

# Shell config files that the Nix installer may modify
_NIX_SHELL_CONFIGS=(
    /etc/bash.bashrc
    /etc/bashrc
    /etc/profile
    /etc/zsh/zshrc
    /etc/zshrc
)

nix::check() {
    _nix::is_installed && _nix::session_ready && _nix::daemon_active && _nix::flakes_enabled
}

nix::status() {
    local issues=()
    _nix::is_installed || issues+=("not installed")
    _nix::is_installed && ! _nix::session_ready && issues+=("restart needed")
    _nix::is_installed && _nix::session_ready && ! _nix::daemon_active && issues+=("daemon not running")
    _nix::is_installed && ! _nix::flakes_enabled && issues+=("flakes not enabled")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

nix::apply() {
    local choice

    while true; do
        local installed=false session_ready=false daemon=false
        _nix::is_installed && installed=true
        _nix::session_ready && session_ready=true
        _nix::daemon_active && daemon=true

        ui::clear_content
        log::nav "Package managers > Configure Nix"
        log::break

        log::info "Current Nix configuration"

        if $installed; then
            if $session_ready; then
                local version
                version="$(nix --version 2>/dev/null || true)"
                log::ok "Nix: installed (${version})"
            else
                log::ok "Nix: installed"
                log::warn "Restart needed to activate Nix in current session"
            fi

            if $daemon; then
                log::ok "Daemon: active"
            else
                log::warn "Daemon: not running"
            fi

            if _nix::flakes_enabled; then
                log::ok "Flakes: enabled"
            else
                log::warn "Flakes: not enabled"
            fi
        else
            log::warn "Nix: not installed"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            if ! $daemon; then
                options+=("Start daemon")
            fi
            if _nix::flakes_enabled; then
                options+=("Disable flakes")
            else
                options+=("Enable flakes")
            fi
            options+=("Remove Nix")
        else
            options+=("Install Nix")
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
            "Install Nix")
                log::break
                log::info "Installing Nix (multi-user daemon mode)"
                log::break
                ui::flush_input
                if sh <(curl --proto '=https' --tlsv1.2 -L "$_NIX_INSTALL_URL") --daemon --yes </dev/tty; then
                    log::break
                    log::ok "Nix installed"
                    log::break
                    log::warn "Restart your shell or run: . /etc/profile.d/nix.sh"
                else
                    log::break
                    log::error "Nix installation failed"
                fi
                ;;
            "Start daemon")
                log::break
                log::info "Starting nix-daemon service"
                ui::flush_input
                if sudo systemctl enable --now nix-daemon.service </dev/tty; then
                    log::ok "Nix daemon started"
                else
                    log::error "Failed to start nix daemon"
                fi
                ;;
            "Enable flakes")
                log::break
                log::info "Enabling flakes and nix-command"
                ui::flush_input
                sudo mkdir -p /etc/nix
                printf 'experimental-features = nix-command flakes\n' | sudo tee -a /etc/nix/nix.conf > /dev/null
                if sudo systemctl restart nix-daemon.service </dev/tty; then
                    log::ok "Flakes enabled"
                else
                    log::warn "Flakes config written but daemon restart failed"
                    log::warn "Try: sudo systemctl restart nix-daemon.service"
                fi
                ;;
            "Disable flakes")
                log::break
                log::info "Disabling flakes"
                ui::flush_input
                sudo sed -i '/experimental-features/d' /etc/nix/nix.conf
                if sudo systemctl restart nix-daemon.service </dev/tty; then
                    log::ok "Flakes disabled"
                else
                    log::warn "Flakes config removed but daemon restart failed"
                fi
                ;;
            "Remove Nix")
                log::break
                _nix::_remove
                ;;
        esac
    done
}

_nix::_remove() {
    # Stop and disable services
    log::info "Stopping nix-daemon service"
    ui::flush_input
    sudo systemctl stop nix-daemon.service </dev/tty
    sudo systemctl disable nix-daemon.socket nix-daemon.service 2>/dev/null
    sudo systemctl daemon-reload
    log::ok "Nix daemon stopped"

    # Remove flakes config if present
    if _nix::flakes_enabled; then
        log::info "Removing flakes configuration"
        sudo rm -f /etc/nix/nix.conf
        log::ok "Flakes configuration removed"
    fi

    # Remove files and directories
    log::info "Removing Nix files"
    sudo rm -rf /nix /etc/nix /etc/profile.d/nix.sh /etc/tmpfiles.d/nix-daemon.conf \
        ~root/.nix-channels ~root/.nix-defexpr ~root/.nix-profile ~root/.cache/nix
    rm -rf "$HOME/.nix-channels" "$HOME/.nix-defexpr" "$HOME/.nix-profile" "$HOME/.cache/nix"
    log::ok "Nix files removed"

    # Remove build users and group
    log::info "Removing Nix build users"
    local i
    for i in $(seq 1 32); do
        sudo userdel "nixbld${i}" 2>/dev/null || true
    done
    sudo groupdel nixbld 2>/dev/null || true
    log::ok "Build users removed"

    # Clean shell config files
    log::info "Cleaning shell configuration files"
    local cfg
    for cfg in "${_NIX_SHELL_CONFIGS[@]}"; do
        if [[ -f "$cfg" ]] && grep -q "nix" "$cfg"; then
            # Restore backup if the installer left one
            if [[ -f "${cfg}.backup-before-nix" ]]; then
                sudo mv "${cfg}.backup-before-nix" "$cfg"
                log::ok "Restored ${cfg} from backup"
            else
                # Remove nix-related lines
                sudo sed -i '/nix-daemon\.sh/d; /nix-profile/d; /\/nix\/store/d' "$cfg"
                log::ok "Cleaned ${cfg}"
            fi
        fi
    done

    log::break
    log::ok "Nix completely removed"
    log::break
    log::warn "Restart your shell to complete cleanup"
}
