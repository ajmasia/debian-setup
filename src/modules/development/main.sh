# Developer tools module

[[ -n "${_MOD_DEVTOOLS_LOADED:-}" ]] && return 0
_MOD_DEVTOOLS_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_DEVTOOLS_TASKS=(
    "${_BUILD_LABEL}|_BUILD_DESC|build::check|build::apply|build::status"
    "${_NODE_LABEL}|_NODE_DESC|node::check|node::apply|node::status"
    "${_PYTHON_LABEL}|_PYTHON_DESC|python::check|python::apply|python::status"
    "${_RUST_LABEL}|_RUST_DESC|rust::check|rust::apply|rust::status"
    "${_GO_LABEL}|_GO_DESC|go::check|go::apply|go::status"
)

devtools::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Developer tools status"
    for task in "${_DEVTOOLS_TASKS[@]}"; do
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

devtools::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_DEVTOOLS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

devtools::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Developer tools"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_DEVTOOLS_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            items+=("${label#Configure }")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::filter \
            --height 12 \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to filter..." \
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
