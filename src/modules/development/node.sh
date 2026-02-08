# Node.js (fnm) developer tool task

[[ -n "${_MOD_NODE_LOADED:-}" ]] && return 0
_MOD_NODE_LOADED=1

_NODE_LABEL="Configure Node.js"
_NODE_DESC="Install or remove fnm (Fast Node Manager) and Node.js LTS."

_NODE_FNM_INSTALL_URL="https://fnm.vercel.app/install"
_NODE_FNM_DIR="${HOME}/.local/share/fnm"

_node::is_installed() {
    [[ -d "$_NODE_FNM_DIR" ]]
}

_node::session_ready() {
    command -v fnm &>/dev/null
}

node::check() {
    _node::is_installed && _node::session_ready
}

node::status() {
    local issues=()
    _node::is_installed || issues+=("not installed")
    _node::is_installed && ! _node::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

node::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _node::is_installed && installed=true
        _node::session_ready && session_ready=true

        ui::clear_content
        log::nav "Development > Environments > Node.js"
        log::break

        log::info "Current Node.js configuration"

        if $installed; then
            if $session_ready; then
                local fnm_version node_version
                fnm_version="$(fnm --version 2>/dev/null || true)"
                node_version="$(fnm current 2>/dev/null || true)"
                log::ok "fnm: installed (${fnm_version})"
                if [[ -n "$node_version" && "$node_version" != "none" ]]; then
                    log::ok "Node.js: ${node_version}"
                else
                    log::warn "Node.js: no version installed"
                fi
            else
                log::ok "fnm: installed"
                log::warn "Restart needed to activate fnm in current session"
            fi
        else
            log::warn "fnm: not installed"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            if $session_ready; then
                local current
                current="$(fnm current 2>/dev/null || true)"
                if [[ -z "$current" || "$current" == "none" ]]; then
                    options+=("Install Node.js LTS")
                fi
            fi
            options+=("Remove fnm")
        else
            options+=("Install fnm")
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
            "Install fnm")
                log::break
                log::info "Installing fnm (Fast Node Manager)"
                log::break
                ui::flush_input
                if curl -fsSL "$_NODE_FNM_INSTALL_URL" | bash; then
                    hash -r
                    log::break
                    log::ok "fnm installed"
                    log::break

                    # Ask whether to install Node.js LTS
                    local install_node
                    install_node="$(gum::choose \
                        --header "Install Node.js LTS now?" \
                        --header.foreground "$HEX_LAVENDER" \
                        --cursor.foreground "$HEX_BLUE" \
                        --item.foreground "$HEX_TEXT" \
                        --selected.foreground "$HEX_GREEN" \
                        "Yes" "No")"

                    if [[ "$install_node" == "Yes" ]]; then
                        log::break
                        # Source fnm for current session
                        export PATH="${_NODE_FNM_DIR}:${PATH}"
                        eval "$(fnm env)"
                        log::info "Installing Node.js LTS"
                        if fnm install --lts; then
                            fnm default lts-latest
                            log::ok "Node.js LTS installed"
                        else
                            log::error "Failed to install Node.js LTS"
                        fi
                    fi

                    log::break
                    log::warn "Restart your shell to activate fnm"
                else
                    log::break
                    log::error "fnm installation failed"
                fi
                ;;
            "Install Node.js LTS")
                log::break
                log::info "Installing Node.js LTS"
                if fnm install --lts; then
                    fnm default lts-latest
                    log::ok "Node.js LTS installed"
                else
                    log::error "Failed to install Node.js LTS"
                fi
                ;;
            "Remove fnm")
                log::break
                log::info "Removing fnm and Node.js"

                # Remove fnm directory
                rm -rf "$_NODE_FNM_DIR"
                log::ok "fnm directory removed"

                # Clean .bashrc
                if [[ -f "$HOME/.bashrc" ]]; then
                    local tmp
                    tmp="$(mktemp)"
                    grep -v 'fnm' "$HOME/.bashrc" > "$tmp" || true
                    mv "$tmp" "$HOME/.bashrc"
                    log::ok "Cleaned .bashrc"
                fi

                hash -r
                log::break
                log::ok "fnm removed"
                log::break
                log::warn "Restart your shell to complete cleanup"
                ;;
        esac
    done
}
