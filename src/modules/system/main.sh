# System settings module - multi-select batch execution

[[ -n "${_MOD_SYSTEM_LOADED:-}" ]] && return 0
_MOD_SYSTEM_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn"
_SYSTEM_TASKS=(
    "${_SUDOERS_LABEL}|_SUDOERS_DESC|sudoers::check|sudoers::apply"
    "${_PWFEEDBACK_LABEL}|_PWFEEDBACK_DESC|pwfeedback::check|pwfeedback::apply"
    "${_EDITOR_LABEL}|_EDITOR_DESC|editor::check|editor::apply"
    "${_ZRAM_LABEL}|_ZRAM_DESC|zram::check|zram::apply"
    "${_APT_LABEL}|_APT_DESC|apt::check|apt::apply"
)

system::log_status() {
    local task label desc_var check_fn apply_fn
    _log::to_file "info" "System core status"
    for task in "${_SYSTEM_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"
        if "$check_fn"; then
            _log::to_file "ok" "${label}"
        else
            _log::to_file "warn" "${label}"
        fi
    done
}

system::has_pending() {
    local task label desc_var check_fn apply_fn
    for task in "${_SYSTEM_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

system::run() {
    local task label desc_var check_fn apply_fn
    local pending completed labels selections selected proceed

    while true; do
        ui::clear_content
        log::nav "1. System core"
        log::break

        # Categorize tasks
        pending=()
        completed=()
        for task in "${_SYSTEM_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"
            if "$check_fn"; then
                completed+=("$label")
            else
                pending+=("$task")
            fi
        done

        # Show completed tasks
        for label in "${completed[@]}"; do
            log::ok "${label}"
        done

        # All tasks done
        if [[ ${#pending[@]} -eq 0 ]]; then
            log::break
            log::ok "All system tasks completed"
            ui::return_or_exit
            return
        fi

        # Spacing between completed and pending sections
        if [[ ${#completed[@]} -gt 0 ]]; then
            log::break
        fi

        # Build labels for multi-select
        labels=()
        for task in "${pending[@]}"; do
            IFS='|' read -r label _ _ _ <<< "$task"
            labels+=("$label")
        done

        # Multi-select menu
        selections="$(gum choose --no-limit \
            --header "Select tasks to run:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${labels[@]}")"

        # Nothing selected → back to parent menu
        if [[ -z "$selections" ]]; then
            return
        fi

        # Collect selected tasks into array (avoid running apply inside read loop)
        local selected_tasks=()
        while IFS= read -r selected; do
            for task in "${pending[@]}"; do
                IFS='|' read -r label _ _ _ <<< "$task"
                if [[ "$label" == "$selected" ]]; then
                    selected_tasks+=("$task")
                    break
                fi
            done
        done <<< "$selections"

        # Execute each selected task outside the read loop
        for task in "${selected_tasks[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"

            ui::clear_content
            log::nav "1. System core > ${label}"
            log::break
            printf "%b%s%b\n" "${COLOR_OVERLAY1}" "${!desc_var}" "${COLOR_RESET}"
            log::break

            proceed="$(gum::choose \
                --header "Proceed?" \
                --header.foreground "$HEX_LAVENDER" \
                --cursor.foreground "$HEX_BLUE" \
                --item.foreground "$HEX_TEXT" \
                --selected.foreground "$HEX_GREEN" \
                "Yes" \
                "No")"

            if [[ "$proceed" == "Yes" ]]; then
                log::break
                "$apply_fn"
            else
                log::warn "Skipped: ${label}"
            fi
        done

        ui::return_or_exit
    done
}
