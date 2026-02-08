# Inotify max_user_watches configuration task

[[ -n "${_MOD_WATCHERS_LOADED:-}" ]] && return 0
_MOD_WATCHERS_LOADED=1

_WATCHERS_LABEL="Configure Inotify Watchers"
_WATCHERS_DESC="Configure fs.inotify limits (watches and instances) for development."

_WATCHERS_CONF="/etc/sysctl.d/60-max-user-watches.conf"

_watchers::is_configured() {
    [[ -f "$_WATCHERS_CONF" ]]
}

_watchers::current_value() {
    cat /proc/sys/fs/inotify/max_user_watches
}

_watchers::current_instances() {
    cat /proc/sys/fs/inotify/max_user_instances
}

_watchers::detect_ram_gb() {
    free -m | awk '/^Mem:/ {print int($2/1024)}'
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
        local current current_inst ram_gb
        current="$(_watchers::current_value)"
        current_inst="$(_watchers::current_instances)"
        ram_gb="$(_watchers::detect_ram_gb)"

        ui::clear_content
        log::nav "System core > Configure inotify watchers"
        log::break

        log::info "Current inotify configuration (detected ${ram_gb} GB RAM)"
        log::ok "max_user_watches: ${current}"
        log::ok "max_user_instances: ${current_inst}"

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
    local ram_gb
    ram_gb="$(_watchers::detect_ram_gb)"

    # --- Step 1: Select watches ---
    local watches_options=()
    local recommended_watches=""

    if [[ "$ram_gb" -le 12 ]]; then
        recommended_watches="262144"
    elif [[ "$ram_gb" -le 24 ]]; then
        recommended_watches="524288"
    elif [[ "$ram_gb" -le 48 ]]; then
        recommended_watches="1048576"
    else
        recommended_watches="2097152"
    fi

    local label
    for pair in "8 GB|262144" "16 GB|524288" "32 GB|1048576" "64 GB|2097152"; do
        label="${pair%%|*} (${pair##*|})"
        if [[ "${pair##*|}" == "$recommended_watches" ]]; then
            label="${label} (recommended)"
        fi
        watches_options+=("$label")
    done
    watches_options+=("Custom")

    local watches_choice
    watches_choice="$(gum::choose \
        --header "Select max_user_watches preset:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${watches_options[@]}")"

    if [[ -z "$watches_choice" ]]; then
        return
    fi

    local watches_value
    if [[ "$watches_choice" == "Custom" ]]; then
        watches_value="$(gum::input \
            --header "Enter max_user_watches value:" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. 524288")"

        if [[ -z "$watches_value" ]]; then
            return
        fi

        if ! [[ "$watches_value" =~ ^[0-9]+$ ]]; then
            log::error "Invalid value (must be a number)"
            return
        fi
    else
        # Extract number from "16 GB (524288)" or "16 GB (524288) (recommended)"
        watches_value="${watches_choice#*(}"
        watches_value="${watches_value%%)*}"
    fi

    # --- Step 2: Select instances ---
    local instances_options=("256" "512 (recommended)" "1024" "Custom")

    local instances_choice
    instances_choice="$(gum::choose \
        --header "Select max_user_instances preset:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${instances_options[@]}")"

    if [[ -z "$instances_choice" ]]; then
        return
    fi

    local instances_value
    if [[ "$instances_choice" == "Custom" ]]; then
        instances_value="$(gum::input \
            --header "Enter max_user_instances value:" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. 512")"

        if [[ -z "$instances_value" ]]; then
            return
        fi

        if ! [[ "$instances_value" =~ ^[0-9]+$ ]]; then
            log::error "Invalid value (must be a number)"
            return
        fi
    else
        # Extract number: "512 (recommended)" → "512", "256" → "256"
        instances_value="${instances_choice%% *}"
    fi

    # --- Step 3: Apply ---
    log::break
    log::info "Setting max_user_watches to ${watches_value}, max_user_instances to ${instances_value}"
    ui::flush_input
    if printf 'fs.inotify.max_user_watches = %s\nfs.inotify.max_user_instances = %s\n' \
        "$watches_value" "$instances_value" | sudo tee "$_WATCHERS_CONF" > /dev/null \
        && sudo sysctl -p "$_WATCHERS_CONF"; then
        log::ok "max_user_watches set to ${watches_value}"
        log::ok "max_user_instances set to ${instances_value}"
    else
        log::error "Failed to apply configuration"
    fi
}
