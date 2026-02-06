# Package managers module

[[ -n "${_MOD_PACKAGES_LOADED:-}" ]] && return 0
_MOD_PACKAGES_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_PACKAGES_TASKS=(
    "${_APT_LABEL}|_APT_DESC|apt::check|apt::apply|apt::status"
    "${_FLATPAK_LABEL}|_FLATPAK_DESC|flatpak::check|flatpak::apply|flatpak::status"
    "${_NIX_LABEL}|_NIX_DESC|nix::check|nix::apply|nix::status"
)

packages::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Package managers status"
    for task in "${_PACKAGES_TASKS[@]}"; do
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

packages::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_PACKAGES_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

packages::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Package managers"
        log::break

        # Show status for each task
        for task in "${_PACKAGES_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            if "$check_fn"; then
                log::ok "${label}"
            else
                local detail
                detail="$($status_fn)"
                log::warn "${label} (${detail})"
            fi
        done

        log::break

        # Build menu: task labels + Back + Exit
        local items=()
        for task in "${_PACKAGES_TASKS[@]}"; do
            IFS='|' read -r label _ _ _ _ <<< "$task"
            items+=("$label")
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
            "Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                # Find and run selected task
                for task in "${_PACKAGES_TASKS[@]}"; do
                    IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
                    if [[ "$label" == "$choice" ]]; then
                        "$apply_fn"
                        break
                    fi
                done
                ;;
        esac
    done
}
