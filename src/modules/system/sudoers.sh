# Sudoers configuration task

[[ -n "${_MOD_SUDOERS_LOADED:-}" ]] && return 0
_MOD_SUDOERS_LOADED=1

_SUDOERS_LABEL="Add user to sudoers"
_SUDOERS_DESC="Creates /etc/sudoers.d/${USER} granting full sudo privileges.
Root password will be required to complete this action."

sudoers::check() {
    [[ -f "/etc/sudoers.d/${USER}" ]]
}

sudoers::apply() {
    log::info "Adding ${USER} to sudoers"
    log::warn "Root password required"
    log::break

    # Drain leftover terminal input from gum
    read -rs -t 0.1 -n 10000 </dev/tty 2>/dev/null || true

    if su -c "echo '${USER} ALL=(ALL:ALL) ALL' > '/etc/sudoers.d/${USER}' && chmod 0440 '/etc/sudoers.d/${USER}'"; then
        log::ok "Sudoers entry created for ${USER}"
    else
        log::error "Failed to create sudoers entry"
    fi
}
