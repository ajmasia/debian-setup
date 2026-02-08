# Inotify max_user_watches configuration task

[[ -n "${_MOD_WATCHERS_LOADED:-}" ]] && return 0
_MOD_WATCHERS_LOADED=1

_WATCHERS_LABEL="Configure Inotify Watchers"
_WATCHERS_DESC="Increase fs.inotify.max_user_watches for large Node.js projects."

_WATCHERS_CONF="/etc/sysctl.d/60-max-user-watches.conf"

_watchers::is_configured() {
    [[ -f "$_WATCHERS_CONF" ]]
}

_watchers::current_value() {
    cat /proc/sys/fs/inotify/max_user_watches
}

watchers::check() {
    _watchers::is_configured
}

watchers::status() {
    if ! watchers::check; then
        printf '%s' "not configured"
    fi
}

watchers::apply() {
    local choice

    while true; do
        local configured=false
        _watchers::is_configured && configured=true
        local current
        current="$(_watchers::current_value)"

        ui::clear_content
        log::nav "System core > Configure inotify watchers"
        log::break

        log::info "Current inotify configuration"
        log::ok "max_user_watches: ${current}"

        if $configured; then
            log::ok "Persistent config: ${_WATCHERS_CONF}"
        else
            log::warn "No persistent config (using system default)"
        fi

        log::break

        local options=()
        if $configured; then
            options+=("Change value" "Remove configuration")
        else
            options+=("Configure watchers")
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
            "Configure watchers"|"Change value")
                _watchers::_select_and_apply
                return
                ;;
            "Remove configuration")
                log::break
                log::info "Removing inotify watchers configuration"
                ui::flush_input
                if sudo rm "$_WATCHERS_CONF" && sudo sysctl -p; then
                    log::ok "Configuration removed (will use system default after reboot)"
                    return
                else
                    log::error "Failed to remove configuration"
                fi
                ;;
        esac
    done
}

_watchers::_select_and_apply() {
    local preset
    preset="$(gum::choose \
        --header "Select preset (by RAM size):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "16 GB (524288)" \
        "32 GB (1048576)" \
        "64 GB (2097152)")"

    if [[ -z "$preset" ]]; then
        log::warn "No preset selected, skipped"
        return
    fi

    local value
    value="${preset##*(}"
    value="${value%)}"

    log::break
    log::info "Setting max_user_watches to ${value}"
    ui::flush_input
    if printf 'fs.inotify.max_user_watches = %s\n' "$value" | sudo tee "$_WATCHERS_CONF" > /dev/null \
        && sudo sysctl -p "$_WATCHERS_CONF"; then
        log::ok "max_user_watches set to ${value}"
    else
        log::error "Failed to apply configuration"
    fi
}
