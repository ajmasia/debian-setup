# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

menu::main() {
    local choice

    while true; do
        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Settings" \
            "Exit")"

        case "$choice" in
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
