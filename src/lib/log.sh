# Logging functions for terminal output

[[ -n "${_LIB_LOG_LOADED:-}" ]] && return 0
_LIB_LOG_LOADED=1

log::info() {
    printf "%b[info]%b %s\n" "${COLOR_BLUE}" "${COLOR_RESET}" "$1"
}

log::error() {
    printf "%b[error]%b %s\n" "${COLOR_RED}" "${COLOR_RESET}" "$1" >&2
}

log::ok() {
    printf "%b[ok]%b %s\n" "${COLOR_GREEN}" "${COLOR_RESET}" "$1"
}

log::warn() {
    printf "%b[warn]%b %s\n" "${COLOR_YELLOW}" "${COLOR_RESET}" "$1"
}

log::break() {
    printf "\n"
}

log::section_break() {
    printf "\n\n"
}
