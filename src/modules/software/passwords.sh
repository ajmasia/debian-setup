# Passwords sub-module

[[ -n "${_MOD_PASSWORDS_LOADED:-}" ]] && return 0
_MOD_PASSWORDS_LOADED=1

_PASSWORDS_LABEL="Configure Password Managers"
_PASSWORDS_DESC="Install and configure password managers."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_PASSWORDS_TASKS=(
    "${_PROTONPASS_LABEL}|_PROTONPASS_DESC|protonpass::check|protonpass::apply|protonpass::status"
    "${_PASSCLI_LABEL}|_PASSCLI_DESC|passcli::check|passcli::apply|passcli::status"
    "${_KEEPASSXC_LABEL}|_KEEPASSXC_DESC|keepassxc::check|keepassxc::apply|keepassxc::status"
    "${_BITWARDEN_LABEL}|_BITWARDEN_DESC|bitwarden::check|bitwarden::apply|bitwarden::status"
)

passwords::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_PASSWORDS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

passwords::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_PASSWORDS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s password managers pending' "$pending"
    fi
}

passwords::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Security > Password Managers"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_PASSWORDS_TASKS[@]}"; do
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
