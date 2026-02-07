# Browsers sub-module

[[ -n "${_MOD_BROWSERS_LOADED:-}" ]] && return 0
_MOD_BROWSERS_LOADED=1

_BROWSERS_LABEL="Configure Browsers"
_BROWSERS_DESC="Install and configure web browsers."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_BROWSERS_TASKS=(
    "${_BRAVE_LABEL}|_BRAVE_DESC|brave::check|brave::apply|brave::status"
    "${_LIBREWOLF_LABEL}|_LIBREWOLF_DESC|librewolf::check|librewolf::apply|librewolf::status"
    "${_MULLVAD_LABEL}|_MULLVAD_DESC|mullvad::check|mullvad::apply|mullvad::status"
    "${_CHROMIUM_LABEL}|_CHROMIUM_DESC|chromium::check|chromium::apply|chromium::status"
)

browsers::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_BROWSERS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

browsers::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_BROWSERS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s browsers pending' "$pending"
    fi
}

browsers::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Browsers"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_BROWSERS_TASKS[@]}"; do
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
