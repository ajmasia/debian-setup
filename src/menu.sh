# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

menu::main() {
    local choice items

    while true; do
        items=("System essentials" "Package managers" "OpenSSH server" "Developer tools" "Software" "Settings" "Exit")

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
            "System essentials")
                system::run
                ui::clear_content
                ;;
            "Package managers")
                packages::run
                ui::clear_content
                ;;
            "OpenSSH server")
                ssh::run
                ui::clear_content
                ;;
            "Developer tools")
                devtools::run
                ui::clear_content
                ;;
            "Software")
                software::run
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
