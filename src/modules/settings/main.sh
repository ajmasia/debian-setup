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
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "System Health" \
            "Logs" \
            "Completions" \
            "About" \
            "Back" \
            "Exit")"

        case "$choice" in
            "System Health")
                ui::clear_content
                health::run
                _UI_DIRTY=1
                ;;
            "Logs")
                logs::run
                ;;
            "Completions")
                completions::run
                ;;
            "About")
                about::run
                ;;
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}
