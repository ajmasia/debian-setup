# System settings module - multi-select batch execution

[[ -n "${_MOD_SYSTEM_LOADED:-}" ]] && return 0
_MOD_SYSTEM_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn"
_SYSTEM_TASKS=(
    "${_SUDOERS_LABEL}|_SUDOERS_DESC|sudoers::check|sudoers::apply"
)

system::run() {
    local task label desc_var check_fn apply_fn
    local pending labels selections selected proceed

    while true; do
        ui::clear_content
        log::nav "System"
        log::break

        # Build list of pending tasks
        pending=()
        for task in "${_SYSTEM_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"
            if ! "$check_fn"; then
                pending+=("$task")
            fi
        done

        # All tasks already done
        if [[ ${#pending[@]} -eq 0 ]]; then
            log::ok "All system tasks completed"
            ui::return_or_exit
            return
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

        # Execute each selected task
        while IFS= read -r selected; do
            for task in "${pending[@]}"; do
                IFS='|' read -r label desc_var check_fn apply_fn <<< "$task"
                if [[ "$label" == "$selected" ]]; then
                    ui::clear_content
                    log::nav "System > ${label}"
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
                    break
                fi
            done
        done <<< "$selections"

        ui::return_or_exit
    done
}
