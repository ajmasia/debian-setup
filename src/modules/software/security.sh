# Security sub-module

[[ -n "${_MOD_SECURITY_LOADED:-}" ]] && return 0
_MOD_SECURITY_LOADED=1

_SECURITY_LABEL="Configure Security"
_SECURITY_DESC="Install and configure security tools."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SECURITY_TASKS=(
    "${_VPNS_LABEL}|_VPNS_DESC|vpns::check|vpns::run|vpns::status"
    "${_PASSWORDS_LABEL}|_PASSWORDS_DESC|passwords::check|passwords::run|passwords::status"
    "${_AUTHENTICATORS_LABEL}|_AUTHENTICATORS_DESC|authenticators::check|authenticators::run|authenticators::status"
    "${_HWKEYS_LABEL}|_HWKEYS_DESC|hwkeys::check|hwkeys::run|hwkeys::status"
    "${_OPENPGP_LABEL}|_OPENPGP_DESC|openpgp::check|openpgp::apply|openpgp::status"
)

security::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SECURITY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

security::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_SECURITY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s categories pending' "$pending"
    fi
}

security::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Security"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_SECURITY_TASKS[@]}"; do
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
