# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

menu::main() {
    local choice items

    while true; do
        items=("System Essentials" "Package managers" "OpenSSH server" "Development" "Shell" "Hardware" "Virtualization" "Software" "UI" "Diagnostics" "Exit")

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
            "System Essentials")
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
            "Development")
                development::run
                ui::clear_content
                ;;
            "Shell")
                shell::run
                ui::clear_content
                ;;
            "Hardware")
                hardware::run
                ui::clear_content
                ;;
            "Virtualization")
                virtualization::run
                ui::clear_content
                ;;
            "Software")
                software::run
                ui::clear_content
                ;;
            "UI")
                ui_module::run
                ui::clear_content
                ;;
            "Diagnostics")
                diagnostics::run
                ui::clear_content
                ;;
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}
