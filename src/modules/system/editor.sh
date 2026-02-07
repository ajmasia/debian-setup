# Default editor configuration task

[[ -n "${_MOD_EDITOR_LOADED:-}" ]] && return 0
_MOD_EDITOR_LOADED=1

_EDITOR_LABEL="Configure Default Editor"
_EDITOR_DESC="Manage vim as default editor with EDITOR/SUDO_EDITOR in ~/.bashrc."

_editor::vim_installed() {
    command -v vim &>/dev/null
}

_editor::has_bashrc_editor() {
    grep -Fq 'export EDITOR=vim' "$HOME/.bashrc"
}

_editor::has_bashrc_sudo_editor() {
    grep -Fq 'export SUDO_EDITOR=$EDITOR' "$HOME/.bashrc"
}

editor::check() {
    _editor::vim_installed && _editor::has_bashrc_editor && _editor::has_bashrc_sudo_editor
}

editor::status() {
    local issues=()
    _editor::vim_installed || issues+=("vim not installed")
    _editor::has_bashrc_editor || issues+=("EDITOR not set")
    _editor::has_bashrc_sudo_editor || issues+=("SUDO_EDITOR not set")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

editor::apply() {
    local choice

    while true; do
        local vim_ok=false editor_ok=false sudo_editor_ok=false
        _editor::vim_installed && vim_ok=true
        _editor::has_bashrc_editor && editor_ok=true
        _editor::has_bashrc_sudo_editor && sudo_editor_ok=true

        ui::clear_content
        log::nav "System core > Configure default editor"
        log::break

        log::info "Current editor configuration"

        if $vim_ok; then
            log::ok "vim: installed"
        else
            log::warn "vim: not installed"
        fi

        if $editor_ok; then
            log::ok "EDITOR=vim in ~/.bashrc"
        else
            log::warn "EDITOR not set in ~/.bashrc"
        fi

        if $sudo_editor_ok; then
            log::ok "SUDO_EDITOR in ~/.bashrc"
        else
            log::warn "SUDO_EDITOR not set in ~/.bashrc"
        fi

        log::break

        local options=()
        if ! $vim_ok || ! $editor_ok || ! $sudo_editor_ok; then
            options+=("Apply full editor setup")
        fi
        if $editor_ok || $sudo_editor_ok; then
            options+=("Remove editor configuration")
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
            "Apply full editor setup")
                log::break
                if ! $vim_ok; then
                    log::info "Installing vim"
                    ui::flush_input
                    if sudo apt install -y vim </dev/tty; then
                        hash -r
                        log::ok "vim installed"
                    else
                        log::error "Failed to install vim"
                        continue
                    fi
                fi

                if ! $editor_ok; then
                    log::info "Adding EDITOR=vim to ~/.bashrc"
                    printf '\nexport EDITOR=vim\n' >> "$HOME/.bashrc"
                    log::ok "EDITOR configured"
                fi

                if ! $sudo_editor_ok; then
                    log::info "Adding SUDO_EDITOR to ~/.bashrc"
                    printf 'export SUDO_EDITOR=$EDITOR\n' >> "$HOME/.bashrc"
                    log::ok "SUDO_EDITOR configured"
                fi

                log::info "Setting vim as system default editor"
                ui::flush_input
                if sudo update-alternatives --set editor /usr/bin/vim.basic </dev/tty; then
                    log::ok "vim set as default editor"
                    return
                else
                    log::error "Failed to set vim as default editor"
                fi
                ;;
            "Remove editor configuration")
                log::break
                if $editor_ok; then
                    log::info "Removing EDITOR from ~/.bashrc"
                    sed -i '/^export EDITOR=vim$/d' "$HOME/.bashrc"
                    log::ok "EDITOR removed"
                fi
                if $sudo_editor_ok; then
                    log::info "Removing SUDO_EDITOR from ~/.bashrc"
                    sed -i '/^export SUDO_EDITOR=\$EDITOR$/d' "$HOME/.bashrc"
                    log::ok "SUDO_EDITOR removed"
                fi
                log::info "Reverting system default editor"
                ui::flush_input
                if sudo update-alternatives --auto editor </dev/tty; then
                    log::ok "System editor reverted to default"
                    return
                else
                    log::error "Failed to revert system editor"
                fi
                ;;
        esac
    done
}
