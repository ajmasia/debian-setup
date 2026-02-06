# UI display functions

[[ -n "${_LIB_UI_LOADED:-}" ]] && return 0
_LIB_UI_LOADED=1

ui::clear() {
    clear
}

ui::header() {
    local version="$1"

    gum::style \
        --foreground "$HEX_BLUE" \
        --border "rounded" \
        --border-foreground "$HEX_LAVENDER" \
        --padding "0 2" \
        --bold \
        "debian-setup v${version}"

    log::break
}

ui::system_info() {
    local hostname kernel os arch cpu ram uptime_str

    hostname="$(system::hostname)"
    kernel="$(system::kernel)"
    os="$(system::os)"
    arch="$(system::arch)"
    cpu="$(system::cpu)"
    ram="$(system::ram_total)"
    uptime_str="$(system::uptime)"

    gum::style \
        --foreground "$HEX_SUBTEXT1" \
        "Host: ${hostname}  |  OS: ${os}  |  Kernel: ${kernel}  |  Arch: ${arch}" \
        "CPU: ${cpu}  |  RAM: ${ram}  |  ${uptime_str}"

    log::break

    log::info "Session started on ${hostname} (${os})"
}
