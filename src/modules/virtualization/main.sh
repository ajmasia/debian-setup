# Virtualization module

[[ -n "${_MOD_VIRTUALIZATION_LOADED:-}" ]] && return 0
_MOD_VIRTUALIZATION_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_VIRTUALIZATION_TASKS=(
    "${_QEMU_LABEL}|_QEMU_DESC|qemu::check|qemu::apply|qemu::status"
)

virtualization::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_VIRTUALIZATION_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

virtualization::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Virtualization status"
    for task in "${_VIRTUALIZATION_TASKS[@]}"; do
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

virtualization::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Virtualization"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_VIRTUALIZATION_TASKS[@]}"; do
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
