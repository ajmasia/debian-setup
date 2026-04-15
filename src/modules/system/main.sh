# System settings module

[[ -n "${_MOD_SYSTEM_LOADED:-}" ]] && return 0
_MOD_SYSTEM_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn[|compat_fn]"
# compat_fn: if non-empty, called to decide if the task is shown (0 = show, 1 = hide)
_SYSTEM_TASKS=(
    "${_SUDOERS_LABEL}|_SUDOERS_DESC|sudoers::check|sudoers::apply|sudoers::status|distro::is_debian"
    "${_PWFEEDBACK_LABEL}|_PWFEEDBACK_DESC|pwfeedback::check|pwfeedback::apply|pwfeedback::status|distro::is_debian"
    "${_EDITOR_LABEL}|_EDITOR_DESC|editor::check|editor::apply|editor::status"
    "${_ZRAM_LABEL}|_ZRAM_DESC|zram::check|zram::apply|zram::status"
    "${_WATCHERS_LABEL}|_WATCHERS_DESC|watchers::check|watchers::apply|watchers::status"
    "${_GRUB_LABEL}|_GRUB_DESC|grub::check|grub::apply|grub::status"
)

system::log_status() {
    local task label desc_var check_fn apply_fn status_fn compat_fn
    _log::to_file "info" "System Essentials status"
    for task in "${_SYSTEM_TASKS[@]}"; do
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

system::has_pending() {
    local task label desc_var check_fn apply_fn status_fn compat_fn
    for task in "${_SYSTEM_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn compat_fn <<< "$task"
        [[ -n "$compat_fn" ]] && ! "$compat_fn" 2>/dev/null && continue
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

system::run() {
    local task label desc_var check_fn apply_fn status_fn compat_fn choice

    while true; do
        ui::clear_content
        log::nav "System Essentials"
        log::break

        # Build menu items (strip "Configure " prefix), skipping incompatible tasks
        local items=() apply_fns=()
        for task in "${_SYSTEM_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn compat_fn <<< "$task"
            [[ -n "$compat_fn" ]] && ! "$compat_fn" 2>/dev/null && continue
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
