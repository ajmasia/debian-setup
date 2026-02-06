# Health check module

[[ -n "${_MOD_HEALTH_LOADED:-}" ]] && return 0
_MOD_HEALTH_LOADED=1

health::run() {
    log::info "Running system health check"
    log::break

    local cpu_usage disk_usage mem_info uptime_str

    # CPU usage (1-second sample)
    cpu_usage="$(top -bn1 | grep '%Cpu' | awk '{printf "%.1f%%", 100 - $8}')"

    # Memory
    mem_info="$(free -h | awk '/^Mem:/ {printf "%s / %s (%.1f%%)", $3, $2, ($3/$2)*100}')"

    # Disk usage (root partition)
    disk_usage="$(df -h / | awk 'NR==2 {printf "%s / %s (%s)", $3, $2, $5}')"

    # Uptime
    uptime_str="$(system::uptime)"

    log::ok "CPU usage:  ${cpu_usage}"
    log::ok "Memory:     ${mem_info}"
    log::ok "Disk (/):   ${disk_usage}"
    log::ok "Uptime:     ${uptime_str}"

    ui::return_or_exit
}
