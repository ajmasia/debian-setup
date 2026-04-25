# UI module (GNOME customization)

[[ -n "${_MOD_UI_MODULE_LOADED:-}" ]] && return 0
_MOD_UI_MODULE_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn[|compat_fn]"
# compat_fn: if non-empty, called to decide if the task is shown (0 = show, 1 = hide)
_UI_TASKS=(
    "${_KEYBOARD_LABEL}|_KEYBOARD_DESC|keyboard::check|keyboard::apply|keyboard::status|session::is_gnome"
    "${_EXTENSIONS_LABEL}|_EXTENSIONS_DESC|extensions::check|extensions::apply|extensions::status|session::is_gnome"
    "${_ICONS_LABEL}|_ICONS_DESC|icons::check|icons::apply|icons::status|session::is_gnome"
    "${_FONTS_LABEL}|_FONTS_DESC|fonts::check|fonts::run|fonts::status"
)

ui_module::log_status() {
    local task label desc_var check_fn apply_fn status_fn compat_fn
    _log::to_file "info" "UI status"
    for task in "${_UI_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn compat_fn <<< "$task"
        [[ -n "$compat_fn" ]] && ! "$compat_fn" 2>/dev/null && continue
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
    local task label desc_var check_fn apply_fn status_fn compat_fn
    for task in "${_UI_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn compat_fn <<< "$task"
        [[ -n "$compat_fn" ]] && ! "$compat_fn" 2>/dev/null && continue
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

ui_module::run() {
    local task label desc_var check_fn apply_fn status_fn compat_fn choice

    while true; do
        ui::clear_content
        log::nav "UI"
        log::break

        # Build menu items (strip "Configure " prefix), skipping incompatible tasks
        local items=() apply_fns=()
        for task in "${_UI_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn compat_fn <<< "$task"
            [[ -n "$compat_fn" ]] && ! "$compat_fn" 2>/dev/null && continue
            items+=("${label#Configure }")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::filter \
            --height 10 \
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
