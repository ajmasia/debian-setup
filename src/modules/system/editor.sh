# Default editor configuration task

[[ -n "${_MOD_EDITOR_LOADED:-}" ]] && return 0
_MOD_EDITOR_LOADED=1

_EDITOR_LABEL="Set vim as default editor"
_EDITOR_DESC="Installs vim if needed, adds EDITOR and SUDO_EDITOR to ~/.bashrc,
and sets vim as system default via update-alternatives."

editor::check() {
    command -v vim &>/dev/null \
        && grep -Fq 'export EDITOR=vim' "$HOME/.bashrc" \
        && grep -Fq 'export SUDO_EDITOR=$EDITOR' "$HOME/.bashrc"
}

editor::apply() {
    # Install vim if needed
    if ! command -v vim &>/dev/null; then
        log::info "Installing vim"
        ui::flush_input
        sudo apt install -y vim
        log::ok "vim installed"
        log::break
    fi

    # Add exports to .bashrc if missing
    if ! grep -Fq 'export EDITOR=vim' "$HOME/.bashrc"; then
        log::info "Adding EDITOR=vim to ~/.bashrc"
        printf '\nexport EDITOR=vim\n' >> "$HOME/.bashrc"
        log::ok "EDITOR configured"
    fi

    if ! grep -Fq 'export SUDO_EDITOR=$EDITOR' "$HOME/.bashrc"; then
        log::info "Adding SUDO_EDITOR to ~/.bashrc"
        printf 'export SUDO_EDITOR=$EDITOR\n' >> "$HOME/.bashrc"
        log::ok "SUDO_EDITOR configured"
    fi

    # Set vim as system default editor
    log::info "Setting vim as system default editor"
    ui::flush_input
    sudo update-alternatives --set editor /usr/bin/vim.basic
    log::ok "vim set as default editor"
}
