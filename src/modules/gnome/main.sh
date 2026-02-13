# UI module (GNOME customization)

[[ -n "${_MOD_UI_MODULE_LOADED:-}" ]] && return 0
_MOD_UI_MODULE_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_UI_TASKS=(
    "${_APPEARANCE_LABEL}|_APPEARANCE_DESC|appearance::check|appearance::run|appearance::status"
    "${_KEYBOARD_LABEL}|_KEYBOARD_DESC|keyboard::check|keyboard::apply|keyboard::status"
    "${_TERMCSS_LABEL}|_TERMCSS_DESC|termcss::check|termcss::apply|termcss::status"
    "${_EXTENSIONS_LABEL}|_EXTENSIONS_DESC|extensions::check|extensions::apply|extensions::status"
    "${_BROWSERTHEMES_LABEL}|_BROWSERTHEMES_DESC|browserthemes::check|browserthemes::apply|browserthemes::status"
    "${_APPTHEMES_LABEL}|_APPTHEMES_DESC|appthemes::check|appthemes::run|appthemes::status"
)

ui_module::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "UI status"
    for task in "${_UI_TASKS[@]}"; do
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

ui_module::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_UI_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

ui_module::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "UI and Theming"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_UI_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            items+=("${label#Configure }")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::filter \
            --height 9 \
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
