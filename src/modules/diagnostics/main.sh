# Diagnostics module

[[ -n "${_MOD_DIAGNOSTICS_LOADED:-}" ]] && return 0
_MOD_DIAGNOSTICS_LOADED=1

diagnostics::run() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Diagnostics"
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
                _UI_DIRTY=1
                ;;
            "Logs")
                logs::run
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
