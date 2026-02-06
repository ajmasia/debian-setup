# Health check module

[[ -n "${_MOD_HEALTH_LOADED:-}" ]] && return 0
_MOD_HEALTH_LOADED=1

_HEALTH_DEPS=(gum curl sudo git)

health::_check_deps() {
    local dep version

    log::info "Dependencies"
    for dep in "${_HEALTH_DEPS[@]}"; do
        if command -v "$dep" &>/dev/null; then
            version="$("$dep" --version 2>/dev/null | head -1 | grep -oP '[\d]+\.[\d]+[\.\d]*' | head -1)"
            log::ok "${dep} ${version:-unknown}"
        else
            log::error "${dep} not found"
        fi
    done
}

health::run() {
    local cpu_usage disk_usage mem_info uptime_str

    log::info "Running system health check"
    log::break

    cpu_usage="$(top -bn1 | grep '%Cpu' | awk '{printf "%.1f%%", 100 - $8}')"
    mem_info="$(free -h | awk '/^Mem:/ {printf "%s / %s (%.1f%%)", $3, $2, ($3/$2)*100}')"
    disk_usage="$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')"
    uptime_str="$(system::uptime)"

    log::info "System status"
    log::ok "CPU usage:  ${cpu_usage}"
    log::ok "Memory:     ${mem_info}"
    log::ok "Disk (/):   ${disk_usage}"
    log::ok "Uptime:     ${uptime_str}"
    log::break

    health::_check_deps

    ui::return_or_exit
}
