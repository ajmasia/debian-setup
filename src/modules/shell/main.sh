# Shell tools module

[[ -n "${_MOD_SHELL_LOADED:-}" ]] && return 0
_MOD_SHELL_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SHELL_TASKS=(
    "${_STARSHIP_LABEL}|_STARSHIP_DESC|starship::check|starship::apply|starship::status"
    "${_ZOXIDE_LABEL}|_ZOXIDE_DESC|zoxide::check|zoxide::apply|zoxide::status"
    "${_ATUIN_LABEL}|_ATUIN_DESC|atuin::check|atuin::apply|atuin::status"
    "${_TMUX_LABEL}|_TMUX_DESC|tmux::check|tmux::apply|tmux::status"
    "${_ZELLIJ_LABEL}|_ZELLIJ_DESC|zellij::check|zellij::apply|zellij::status"
)

shell::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "Shell tools status"
    for task in "${_SHELL_TASKS[@]}"; do
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

shell::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SHELL_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

shell::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Shell Tools"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_SHELL_TASKS[@]}"; do
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
