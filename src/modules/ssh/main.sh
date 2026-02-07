# SSH module

[[ -n "${_MOD_SSH_LOADED:-}" ]] && return 0
_MOD_SSH_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SSH_TASKS=(
    "${_SSH_SERVER_LABEL}|_SSH_SERVER_DESC|ssh_server::check|ssh_server::apply|ssh_server::status"
    "${_SSH_ACCESS_LABEL}|_SSH_ACCESS_DESC|ssh_access::check|ssh_access::apply|ssh_access::status"
    "${_SSH_KEYS_LABEL}|_SSH_KEYS_DESC|ssh_keys::check|ssh_keys::apply|ssh_keys::status"
    "${_SSH_CONFIG_LABEL}|_SSH_CONFIG_DESC|ssh_config::check|ssh_config::apply|ssh_config::status"
    "${_SSH_SIGNING_LABEL}|_SSH_SIGNING_DESC|ssh_signing::check|ssh_signing::apply|ssh_signing::status"
)

ssh::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "SSH tasks status"
    for task in "${_SSH_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            _log::to_file "ok" "${label}"
        else
            local detail
            detail="$($status_fn)"
            _log::to_file "warn" "${label} (${detail})"
        fi
    done
}

ssh::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SSH_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

ssh::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "OpenSSH server"
        log::break

        # Show warnings for tasks that need attention
        local has_warnings=false
        for task in "${_SSH_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            if ! "$check_fn"; then
                has_warnings=true
                local detail
                detail="$($status_fn)"
                log::warn "${label} (${detail})"
            fi
        done

        if $has_warnings; then
            log::break
        fi

        # Build menu: "Edit X" if configured, "Configure X" if not
        local items=() apply_fns=()
        for task in "${_SSH_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            local display_label="$label"
            if "$check_fn" || [[ "$($status_fn)" != *"not "* ]]; then
                local base="${label#Configure }"
                if [[ "$base" == *" "* ]]; then
                    display_label="Edit ${base}"
                else
                    display_label="Edit ${base} config"
                fi
            fi
            items+=("$display_label")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${items[@]}")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                # Find and run selected task by display label
                local i
                for i in "${!items[@]}"; do
                    if [[ "${items[$i]}" == "$choice" ]]; then
                        "${apply_fns[$i]}"
                        break
                    fi
                done
                ;;
        esac
    done
}
