# UI display functions

[[ -n "${_LIB_UI_LOADED:-}" ]] && return 0
_LIB_UI_LOADED=1

_UI_CONTENT_ROW=0
_UI_SESSION_LOG_START=0
_UI_VERSION=""
_UI_DIRTY=0
_UI_SPIN_PID=0

ui::_cursor_row() {
    local row col
    IFS=';' read -rs -d'R' -p $'\033[6n' row col || true
    printf '%s' "${row#*[}"
}

ui::clear() {
    clear
}

ui::_paint_header() {
    gum::style \
        --foreground "$HEX_MAUVE" \
        --border "rounded" \
        --border-foreground "$HEX_LAVENDER" \
        --padding "0 2" \
        --bold \
        "debian-setup v${_UI_VERSION}  (ds)"

    gum::style \
        --foreground "$HEX_OVERLAY1" \
        "Post-install automation for the impatient developer"

    log::break

    _UI_CONTENT_ROW="$(ui::_cursor_row)"
}

ui::clear_content() {
    if [[ $_UI_DIRTY -eq 1 ]]; then
        # Terminal likely scrolled past header — full repaint
        _UI_DIRTY=0
        tput cup 0 0
        tput ed
        log::break
        ui::_paint_header
    else
        # Fast path — header still visible, clear content area only
        tput cup "$((_UI_CONTENT_ROW - 1))" 0
        tput ed
    fi
}

ui::header() {
    local version="$1"
    _UI_VERSION="$version"
    ui::_paint_header
}

ui::spin_start() {
    local title="${1:-Loading...}"
    (
        local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
        local i=0 len=${#chars}
        while true; do
            printf "\r%b%s%b %b%s%b" \
                "${COLOR_LAVENDER}" "${chars:i%len:1}" "${COLOR_RESET}" \
                "${COLOR_SUBTEXT0}" "$title" "${COLOR_RESET}"
            i=$((i + 1))
            sleep 0.08
        done
    ) &
    _UI_SPIN_PID=$!
}

ui::spin_stop() {
    if [[ $_UI_SPIN_PID -ne 0 ]]; then
        kill "$_UI_SPIN_PID" 2>/dev/null
        wait "$_UI_SPIN_PID" 2>/dev/null || true
        _UI_SPIN_PID=0
        printf "\r\033[K"
    fi
}

ui::flush_input() {
    _UI_DIRTY=1
    sleep 0.5
    stty sane </dev/tty 2>/dev/null || true
    while read -rs -t 0.1 -n 1 </dev/tty 2>/dev/null; do :; done
}

ui::return_or_exit() {
    local choice

    log::break
    choice="$(gum::choose \
        --header "What now?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Back" \
        "Exit")"

    if [[ "$choice" == "Exit" ]]; then
        ui::clear_content
        ui::goodbye
    fi
}

ui::session_info() {
    local user hostname os_name date_str log_file

    user="$(whoami)"
    hostname="$(system::hostname)"
    os_name="$(system::os)"
    date_str="$(date '+%Y-%m-%d %H:%M:%S')"

    log_file="$(xdg::log_file)"
    touch "$log_file"
    _UI_SESSION_LOG_START="$(wc -l < "$log_file")"

    log::info "${date_str} - Session started by ${user}@${hostname} running ${os_name}"
}

ui::goodbye() {
    local log_file session_log

    log_file="$(xdg::log_file)"
    session_log="$(tail -n +"$((_UI_SESSION_LOG_START + 1))" "$log_file")"

    if [[ -n "$session_log" ]]; then
        gum::style \
            --foreground "$HEX_OVERLAY1" \
            "Session log:"
        log::break

        printf "%b%s%b\n" "${COLOR_SUBTEXT0}" "$session_log" "${COLOR_RESET}"
    fi

    log::break
    log::ok "Goodbye!"

    exit 0
}
