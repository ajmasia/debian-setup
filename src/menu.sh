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
            "Health" \
            "Exit")"

        case "$choice" in
            "Health")
                ui::clear
                ui::header "$VERSION"
                health::run
                ui::clear
                ui::header "$VERSION"
                ui::system_info
                log::break
                ;;
            "Exit")
                log::break
                log::ok "Goodbye!"
                log::break
                exit 0
                ;;
        esac
    done
}
