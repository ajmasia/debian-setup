# Fonts sub-module (Nerd Fonts)

[[ -n "${_MOD_FONTS_LOADED:-}" ]] && return 0
_MOD_FONTS_LOADED=1

_FONTS_LABEL="Configure Fonts"
_FONTS_DESC="Install font families."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_FONTS_TASKS=(
    "${_NERDFONTS_LABEL}|_NERDFONTS_DESC|nerdfonts::check|nerdfonts::apply|nerdfonts::status"
)

fonts::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_FONTS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

fonts::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_FONTS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s fonts pending' "$pending"
    fi
}

fonts::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Fonts"
        log::break

        # Show warnings for tasks that need attention
        local has_warnings=false
        for task in "${_FONTS_TASKS[@]}"; do
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
        for task in "${_FONTS_TASKS[@]}"; do
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
