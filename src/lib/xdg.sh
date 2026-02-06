# XDG Base Directory support

[[ -n "${_LIB_XDG_LOADED:-}" ]] && return 0
_LIB_XDG_LOADED=1

readonly _XDG_APP_NAME="debian-setup"

xdg::state_dir() {
    printf "%s/%s" "${XDG_STATE_HOME:-$HOME/.local/state}" "${_XDG_APP_NAME}"
}

xdg::log_dir() {
    printf "%s/logs" "$(xdg::state_dir)"
}

xdg::log_file() {
    printf "%s/%s.log" "$(xdg::log_dir)" "$(date +%Y-%m-%d)"
}

xdg::init() {
    local log_dir
    log_dir="$(xdg::log_dir)"

    if [[ ! -d "$log_dir" ]]; then
        mkdir -p "$log_dir"
    fi
}
