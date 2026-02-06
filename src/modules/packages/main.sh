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

        # Show warnings for tasks that need attention
        for task in "${_PACKAGES_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            if ! "$check_fn"; then
                local detail
                detail="$($status_fn)"
                log::warn "${label} (${detail})"
            fi
        done

        log::break

        # Build menu: "Edit X" if configured, "Configure X" if not
        local items=() apply_fns=()
        for task in "${_PACKAGES_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            local display_label="$label"
            if "$check_fn" || [[ "$($status_fn)" != *"not installed"* ]]; then
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
            "Back")
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
