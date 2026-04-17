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

_UPDATE_CHECK_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/debian-setup/latest-version"
_UPDATE_CHECK_MAX_AGE=86400

system::_update_cache_stale() {
    [[ ! -f "$_UPDATE_CHECK_CACHE" ]] && return 0
    local mtime now
    mtime=$(stat -c %Y "$_UPDATE_CHECK_CACHE" 2>/dev/null || echo 0)
    now=$(date +%s)
    (( now - mtime > _UPDATE_CHECK_MAX_AGE ))
}

system::_fetch_latest_version() {
    curl -fsSL --connect-timeout 3 \
        "https://raw.githubusercontent.com/ajmasia/debian-setup/main/VERSION" \
        2>/dev/null
}

system::check_update() {
    local current="$1"

    if system::_update_cache_stale; then
        (
            local latest
            latest="$(system::_fetch_latest_version)"
            if [[ -n "$latest" ]]; then
                mkdir -p "$(dirname "$_UPDATE_CHECK_CACHE")"
                printf '%s' "$latest" > "$_UPDATE_CHECK_CACHE"
            fi
        ) &>/dev/null &
        disown
        return 0
    fi

    local latest
    latest="$(cat "$_UPDATE_CHECK_CACHE" 2>/dev/null)"
    [[ -z "$latest" || "$latest" == "$current" ]] && return 0

    if [[ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)" == "$latest" ]]; then
        log::info "⚡ New version available: v${latest} — run ds --update"
    fi
}
