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

system::distro_id() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        printf '%s' "${ID:-unknown}"
    else
        printf 'unknown'
    fi
}

distro::is_debian() {
    [[ "${DISTRO_ID:-}" == "debian" ]]
}

system::package_managers() {
    local managers=()
    local mgr
    for mgr in apt nala flatpak snap nix brew; do
        command -v "$mgr" &>/dev/null && managers+=("$mgr")
    done
    printf '%s' "${managers[*]}"
}

distro::is_ubuntu() {
    [[ "${DISTRO_ID:-}" == "ubuntu" ]]
}

session::is_gnome() {
    [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]] || [[ "${DESKTOP_SESSION:-}" == *"gnome"* ]]
}
