# Logging functions for terminal and file output

[[ -n "${_LIB_LOG_LOADED:-}" ]] && return 0
_LIB_LOG_LOADED=1

_log::to_file() {
    local level="$1"
    local message="$2"
    local log_file

    log_file="$(xdg::log_file)"
    printf "%s [%s] %s\n" "$(date '+%H:%M:%S')" "$level" "$message" >> "$log_file"
}

log::info() {
    printf "%b[info]%b %s\n" "${COLOR_BLUE}" "${COLOR_RESET}" "$1"
    _log::to_file "info" "$1"
}

log::error() {
    printf "%b[error]%b %s\n" "${COLOR_RED}" "${COLOR_RESET}" "$1" >&2
    _log::to_file "error" "$1"
}

log::ok() {
    printf "%b[ok]%b %s\n" "${COLOR_GREEN}" "${COLOR_RESET}" "$1"
    _log::to_file "ok" "$1"
}

log::warn() {
    printf "%b[warn]%b %s\n" "${COLOR_YELLOW}" "${COLOR_RESET}" "$1"
    _log::to_file "warn" "$1"
}

log::nav() {
    printf "%b[>]%b %s\n" "${COLOR_LAVENDER}" "${COLOR_RESET}" "$1"
}

log::break() {
    printf "\n"
}
