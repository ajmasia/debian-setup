# Hardware module

[[ -n "${_MOD_HARDWARE_LOADED:-}" ]] && return 0
_MOD_HARDWARE_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_HARDWARE_TASKS=(
    "${_SLIMBOOK_LABEL}|_SLIMBOOK_DESC|slimbook::check|slimbook::apply|slimbook::status"
)

hardware::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_HARDWARE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

hardware::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Hardware status"
    for task in "${_HARDWARE_TASKS[@]}"; do
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

hardware::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Hardware Support"
        log::break

        # Show warnings for tasks that need attention
        local has_warnings=false
        for task in "${_HARDWARE_TASKS[@]}"; do
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

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_HARDWARE_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            items+=("${label#Configure }")
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
