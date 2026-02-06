# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

menu::main() {
    local choice items

    while true; do
        items=()

        if system::has_pending; then
            items+=("1. System core")
        else
            printf "%b[info]%b %bAll system core tasks completed%b\n\n" \
                "${COLOR_SURFACE2}" "${COLOR_RESET}" \
                "${COLOR_SURFACE2}" "${COLOR_RESET}"
        fi

        items+=("Settings" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${items[@]}")"

        case "$choice" in
            "1. System core")
                system::run
                ui::clear_content
                ;;
            "Settings")
                settings::run
                ui::clear_content
                ;;
            "Exit")
                ui::goodbye
                ;;
        esac
    done
}
