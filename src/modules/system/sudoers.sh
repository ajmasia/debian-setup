# Sudoers configuration task

[[ -n "${_MOD_SUDOERS_LOADED:-}" ]] && return 0
_MOD_SUDOERS_LOADED=1

_SUDOERS_LABEL="Configure Sudoers"
_SUDOERS_DESC="Manage /etc/sudoers.d/${USER} for sudo privileges."

sudoers::check() {
    [[ -f "/etc/sudoers.d/${USER}" ]]
}

sudoers::status() {
    if ! sudoers::check; then
        printf '%s' "not configured"
    fi
}

sudoers::apply() {
    local choice

    while true; do
        local configured=false
        sudoers::check && configured=true

        ui::clear_content
        log::nav "System core > Configure sudoers"
        log::break

        log::info "Current sudoers configuration"

        if $configured; then
            log::ok "Sudoers entry: /etc/sudoers.d/${USER}"
        else
            log::warn "No sudoers entry for ${USER}"
        fi

        log::break

        local options=()
        if $configured; then
            options+=("Remove sudoers entry")
        else
            options+=("Add sudoers entry")
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
            "Add sudoers entry")
                log::break
                log::info "Adding ${USER} to sudoers"
                log::warn "Root password required"
                log::break
                ui::flush_input
                if su -c "echo '${USER} ALL=(ALL:ALL) ALL' > '/etc/sudoers.d/${USER}' && chmod 0440 '/etc/sudoers.d/${USER}'" </dev/tty; then
                    log::ok "Sudoers entry created for ${USER}"
                    return
                else
                    log::error "Failed to create sudoers entry"
                fi
                ;;
            "Remove sudoers entry")
                log::break
                log::warn "You will lose sudo access for ${USER}"
                log::info "Removing sudoers entry"
                log::warn "Root password required"
                log::break
                ui::flush_input
                if su -c "rm '/etc/sudoers.d/${USER}'" </dev/tty; then
                    log::ok "Sudoers entry removed"
                    return
                else
                    log::error "Failed to remove sudoers entry"
                fi
                ;;
        esac
    done
}
