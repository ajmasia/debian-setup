# Hardware Keys sub-module

[[ -n "${_MOD_HWKEYS_LOADED:-}" ]] && return 0
_MOD_HWKEYS_LOADED=1

_HWKEYS_LABEL="Configure Hardware Keys"
_HWKEYS_DESC="Install and configure hardware key tools."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_HWKEYS_TASKS=(
    "${_YUBIKEY_LABEL}|_YUBIKEY_DESC|yubikey::check|yubikey::apply|yubikey::status"
    "${_NITROKEY_LABEL}|_NITROKEY_DESC|nitrokey::check|nitrokey::apply|nitrokey::status"
)

hwkeys::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_HWKEYS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

hwkeys::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_HWKEYS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s hardware keys pending' "$pending"
    fi
}

hwkeys::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Security > Hardware Keys"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_HWKEYS_TASKS[@]}"; do
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
