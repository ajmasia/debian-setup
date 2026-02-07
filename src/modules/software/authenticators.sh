# Authenticators sub-module

[[ -n "${_MOD_AUTHENTICATORS_LOADED:-}" ]] && return 0
_MOD_AUTHENTICATORS_LOADED=1

_AUTHENTICATORS_LABEL="Configure Authenticators"
_AUTHENTICATORS_DESC="Install and configure authenticator apps."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_AUTHENTICATORS_TASKS=(
    "${_PROTONAUTH_LABEL}|_PROTONAUTH_DESC|protonauth::check|protonauth::apply|protonauth::status"
    "${_YUBICOAUTH_LABEL}|_YUBICOAUTH_DESC|yubicoauth::check|yubicoauth::apply|yubicoauth::status"
)

authenticators::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_AUTHENTICATORS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

authenticators::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_AUTHENTICATORS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s authenticators pending' "$pending"
    fi
}

authenticators::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Security > Authenticators"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_AUTHENTICATORS_TASKS[@]}"; do
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
