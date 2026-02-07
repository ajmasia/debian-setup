# VPNs sub-module

[[ -n "${_MOD_VPNS_LOADED:-}" ]] && return 0
_MOD_VPNS_LOADED=1

_VPNS_LABEL="Configure VPN"
_VPNS_DESC="Install and configure VPN clients."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_VPNS_TASKS=(
    "${_MULLVADVPN_LABEL}|_MULLVADVPN_DESC|mullvadvpn::check|mullvadvpn::apply|mullvadvpn::status"
    "${_PROTONVPN_LABEL}|_PROTONVPN_DESC|protonvpn::check|protonvpn::apply|protonvpn::status"
)

vpns::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_VPNS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

vpns::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_VPNS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s VPN pending' "$pending"
    fi
}

vpns::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Security > VPN"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_VPNS_TASKS[@]}"; do
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
