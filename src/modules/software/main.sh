# Software module

[[ -n "${_MOD_SOFTWARE_LOADED:-}" ]] && return 0
_MOD_SOFTWARE_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SOFTWARE_TASKS=(
    "${_UTILS_LABEL}|_UTILS_DESC|utils::check|utils::apply|utils::status"
    "${_MEDIA_LABEL}|_MEDIA_DESC|media::check|media::apply|media::status"
    "${_EDITORS_LABEL}|_EDITORS_DESC|editors::check|editors::run|editors::status"
    "${_TERMINALS_LABEL}|_TERMINALS_DESC|terminals::check|terminals::run|terminals::status"
)

software::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Software status"
    for task in "${_SOFTWARE_TASKS[@]}"; do
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

software::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SOFTWARE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

software::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software"
        log::break

        # Show warnings for tasks that need attention
        local has_warnings=false
        for task in "${_SOFTWARE_TASKS[@]}"; do
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
        for task in "${_SOFTWARE_TASKS[@]}"; do
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
