# Log management functions

[[ -n "${_MOD_LOGS_LOADED:-}" ]] && return 0
_MOD_LOGS_LOADED=1

logs::view() {
    local log_file editor

    log_file="$(xdg::log_file)"
    editor="${EDITOR:-less}"

    if [[ ! -f "$log_file" ]]; then
        log::warn "No log file for today"
        return
    fi

    log::info "Viewing today's log"
    "$editor" "$log_file"
}

logs::delete() {
    local log_file choice

    log_file="$(xdg::log_file)"

    if [[ ! -f "$log_file" ]]; then
        log::warn "No log file for today"
        return
    fi

    log::warn "This will delete today's log: ${log_file}"
    choice="$(gum::choose \
        --header "Are you sure?" \
        --header.foreground "$HEX_YELLOW" \
        --cursor.foreground "$HEX_RED" \
        "No" \
        "Yes")"

    if [[ "$choice" == "Yes" ]]; then
        log::info "Deleting today's log"
        rm "$log_file"
        log::ok "Log deleted"
    fi
}

logs::clean() {
    local log_dir choice count

    log_dir="$(xdg::log_dir)"
    count="$(find "$log_dir" -name '*.log' 2>/dev/null | wc -l)"

    if [[ "$count" -eq 0 ]]; then
        log::warn "No log files found"
        return
    fi

    log::warn "This will delete all ${count} log file(s) in ${log_dir}"
    choice="$(gum::choose \
        --header "Are you sure?" \
        --header.foreground "$HEX_YELLOW" \
        --cursor.foreground "$HEX_RED" \
        "No" \
        "Yes")"

    if [[ "$choice" == "Yes" ]]; then
        log::info "Cleaning all logs"
        rm -f "${log_dir}"/*.log
        log::ok "All logs cleaned"
    fi
}

logs::run() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Diagnostics > Logs"
        log::break

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "View today's log" \
            "Delete today's log" \
            "Clean all logs" \
            "Back" \
            "Exit")"

        case "$choice" in
            "View today's log")
                logs::view
                ;;
            "Delete today's log")
                logs::delete
                ;;
            "Clean all logs")
                logs::clean
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
