# System information functions

[[ -n "${_LIB_SYSTEM_LOADED:-}" ]] && return 0
_LIB_SYSTEM_LOADED=1

system::hostname() {
    hostname
}

system::kernel() {
    uname -r
}

system::os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf "%s" "${PRETTY_NAME:-Unknown}"
    else
        printf "Unknown"
    fi
}

system::arch() {
    uname -m
}

system::cpu() {
    if [[ -f /proc/cpuinfo ]]; then
        grep -m1 'model name' /proc/cpuinfo | cut -d: -f2 | sed 's/^ //'
    else
        printf "Unknown"
    fi
}

system::ram_total() {
    if command -v free &>/dev/null; then
        free -h | awk '/^Mem:/ {print $2}'
    else
        printf "Unknown"
    fi
}

system::uptime() {
    uptime -p 2>/dev/null || uptime
}
