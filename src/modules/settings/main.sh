# Settings module

[[ -n "${_MOD_SETTINGS_LOADED:-}" ]] && return 0
_MOD_SETTINGS_LOADED=1

settings::run() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Settings"
        log::break

        choice="$(gum::choose \
            --header "Select a category:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Health" \
            "Logs" \
            "Back" \
            "Exit")"

        case "$choice" in
            "Health")
                ui::clear_content
                health::run
                ;;
            "Logs")
                logs::run
                ;;
            "Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}
