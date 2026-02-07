# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

menu::main() {
    local choice items

    while true; do
        items=("System core" "Package managers" "SSH" "Settings" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${items[@]}")"

        case "$choice" in
            "System core")
                system::run
                ui::clear_content
                ;;
            "Package managers")
                packages::run
                ui::clear_content
                ;;
            "SSH")
                ssh::run
                ui::clear_content
                ;;
            "Settings")
                settings::run
                ui::clear_content
                ;;
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}
