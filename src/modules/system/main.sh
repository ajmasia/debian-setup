# System settings module

[[ -n "${_MOD_SYSTEM_LOADED:-}" ]] && return 0
_MOD_SYSTEM_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SYSTEM_TASKS=(
    "${_SUDOERS_LABEL}|_SUDOERS_DESC|sudoers::check|sudoers::apply|sudoers::status"
    "${_PWFEEDBACK_LABEL}|_PWFEEDBACK_DESC|pwfeedback::check|pwfeedback::apply|pwfeedback::status"
    "${_EDITOR_LABEL}|_EDITOR_DESC|editor::check|editor::apply|editor::status"
    "${_ZRAM_LABEL}|_ZRAM_DESC|zram::check|zram::apply|zram::status"
    "${_KERNEL_LABEL}|_KERNEL_DESC|kernel::check|kernel::apply|kernel::status"
    "${_SLIMBOOK_LABEL}|_SLIMBOOK_DESC|slimbook::check|slimbook::apply|slimbook::status"
)

system::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "System essentials status"
    for task in "${_SYSTEM_TASKS[@]}"; do
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

system::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SYSTEM_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

system::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "System essentials"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_SYSTEM_TASKS[@]}"; do
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
