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
    log::break

    health::_check_system_tasks
    log::break
    health::_check_packages_tasks
    log::break
    health::_check_ssh_tasks
    log::break
    health::_check_devtools_tasks
    log::break
    health::_check_shell_tasks
    log::break
    health::_check_hardware_tasks
    log::break
    health::_check_software_tasks
    log::break
    health::_check_gnome_tasks

    ui::return_or_exit
}

health::_check_system_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "System Essentials tasks"
    for task in "${_SYSTEM_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_packages_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "Package manager tasks"
    for task in "${_PACKAGES_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_ssh_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "SSH tasks"
    for task in "${_SSH_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_devtools_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "Developer tools tasks"
    for task in "${_DEVTOOLS_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_shell_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "Shell tools tasks"
    for task in "${_SHELL_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_hardware_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "Hardware tasks"
    for task in "${_HARDWARE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_software_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "Software tasks"
    for task in "${_SOFTWARE_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}

health::_check_gnome_tasks() {
    local task label desc_var check_fn apply_fn status_fn

    log::info "GNOME tasks"
    for task in "${_GNOME_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            log::ok "${label}"
        else
            local detail
            detail="$($status_fn)"
            log::warn "${label} (${detail})"
        fi
    done
}
