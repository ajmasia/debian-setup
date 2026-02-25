# Appearance sub-module (GTK Theme, Icons, Cursors, Terminal Profile)

[[ -n "${_MOD_APPEARANCE_LOADED:-}" ]] && return 0
_MOD_APPEARANCE_LOADED=1

_APPEARANCE_LABEL="Configure Appearance"
_APPEARANCE_DESC="Install Catppuccin Mocha theme, icons, cursors and terminal profile."

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_APPEARANCE_TASKS=(
    "${_GTKTHEME_LABEL}|_GTKTHEME_DESC|gtktheme::check|gtktheme::apply|gtktheme::status"
    "${_ICONS_LABEL}|_ICONS_DESC|icons::check|icons::apply|icons::status"
    "${_CURSORS_LABEL}|_CURSORS_DESC|cursors::check|cursors::apply|cursors::status"
    "${_TERMPROFILE_LABEL}|_TERMPROFILE_DESC|termprofile::check|termprofile::apply|termprofile::status"
    "${_WINDOWBUTTONS_LABEL}|_WINDOWBUTTONS_DESC|windowbuttons::check|windowbuttons::apply|windowbuttons::status"
)

appearance::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_APPEARANCE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

appearance::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_APPEARANCE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s appearance tasks pending' "$pending"
    fi
}

appearance::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "GNOME > Appearance"
        log::break

        # Build menu items (strip "Configure " prefix)
        local items=() apply_fns=()
        for task in "${_APPEARANCE_TASKS[@]}"; do
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
