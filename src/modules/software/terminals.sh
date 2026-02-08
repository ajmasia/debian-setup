# Terminals sub-module (Alacritty, Kitty, Ghostty, Ptyxis)

[[ -n "${_MOD_TERMINALS_LOADED:-}" ]] && return 0
_MOD_TERMINALS_LOADED=1

_TERMINALS_LABEL="Configure Terminals"
_TERMINALS_DESC="Install and configure terminal emulators."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_TERMINALS_TASKS=(
    "${_ALACRITTY_LABEL}|_ALACRITTY_DESC|alacritty::check|alacritty::apply|alacritty::status"
    "${_KITTY_LABEL}|_KITTY_DESC|kitty::check|kitty::apply|kitty::status"
    "${_PTYXIS_LABEL}|_PTYXIS_DESC|ptyxis::check|ptyxis::apply|ptyxis::status"
)

terminals::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_TERMINALS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

terminals::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_TERMINALS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s terminals pending' "$pending"
    fi
}

terminals::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Terminals"
        log::break

        # Show warnings for tasks that need attention
        local has_warnings=false
        for task in "${_TERMINALS_TASKS[@]}"; do
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
        for task in "${_TERMINALS_TASKS[@]}"; do
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
