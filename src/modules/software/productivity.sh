# Productivity sub-module

[[ -n "${_MOD_PRODUCTIVITY_LOADED:-}" ]] && return 0
_MOD_PRODUCTIVITY_LOADED=1

_PRODUCTIVITY_LABEL="Configure Productivity"
_PRODUCTIVITY_DESC="Install and configure productivity apps."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_PRODUCTIVITY_TASKS=(
    "${_GIMP_LABEL}|_GIMP_DESC|gimp::check|gimp::apply|gimp::status"
    "${_INKSCAPE_LABEL}|_INKSCAPE_DESC|inkscape::check|inkscape::apply|inkscape::status"
    "${_ONLYOFFICE_LABEL}|_ONLYOFFICE_DESC|onlyoffice::check|onlyoffice::apply|onlyoffice::status"
    "${_LIBREOFFICE_LABEL}|_LIBREOFFICE_DESC|libreoffice::check|libreoffice::apply|libreoffice::status"
    "${_NEXTCLOUD_LABEL}|_NEXTCLOUD_DESC|nextcloud::check|nextcloud::apply|nextcloud::status"
    "${_LOCALSEND_LABEL}|_LOCALSEND_DESC|localsend::check|localsend::apply|localsend::status"
)

productivity::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_PRODUCTIVITY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

productivity::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_PRODUCTIVITY_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s productivity apps pending' "$pending"
    fi
}

productivity::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Productivity"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_PRODUCTIVITY_TASKS[@]}"; do
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
