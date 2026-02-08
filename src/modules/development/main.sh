# Development module

[[ -n "${_MOD_DEVELOPMENT_LOADED:-}" ]] && return 0
_MOD_DEVELOPMENT_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_DEVELOPMENT_TASKS=(
    "${_ENVIRONMENTS_LABEL}|_ENVIRONMENTS_DESC|environments::check|environments::run|environments::status"
    "${_DEVTOOLS_LABEL}|_DEVTOOLS_DESC|devtools::check|devtools::run|devtools::status"
    "${_AI_LABEL}|_AI_DESC|ai::check|ai::run|ai::status"
)

development::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Development status"

    # Log sub-registries
    local sub_tasks
    for sub_tasks in _ENVIRONMENTS_TASKS _DEVTOOLS_TASKS _AI_TASKS; do
        local -n tasks_ref="$sub_tasks"
        for task in "${tasks_ref[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            if "$check_fn"; then
                _log::to_file "ok" "${label}"
            else
                local detail
                detail="$($status_fn)"
                _log::to_file "warn" "${label} (${detail})"
            fi
        done
    done
}

development::has_pending() {
    local sub_tasks
    for sub_tasks in _ENVIRONMENTS_TASKS _DEVTOOLS_TASKS _AI_TASKS; do
        local -n tasks_ref="$sub_tasks"
        local task label desc_var check_fn apply_fn status_fn
        for task in "${tasks_ref[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            if ! "$check_fn"; then
                return 0
            fi
        done
    done
    return 1
}

development::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Development"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_DEVELOPMENT_TASKS[@]}"; do
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
