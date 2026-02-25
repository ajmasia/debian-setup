# Health check module

[[ -n "${_MOD_HEALTH_LOADED:-}" ]] && return 0
_MOD_HEALTH_LOADED=1

_HEALTH_DEPS=(gum curl git)
[[ $EUID -ne 0 ]] && _HEALTH_DEPS+=(sudo)

# Groups for task summary: "Label|array1 array2 ..."
_HEALTH_GROUPS=(
    "System Essentials|_SYSTEM_TASKS"
    "Package Managers|_PACKAGES_TASKS"
    "OpenSSH Server|_SSH_TASKS"
    "Dotfiles|_DOTFILES_TASKS"
    "Shell Tools|_SHELL_TASKS"
    "Hardware Support|_HARDWARE_TASKS"
    "Git|_GIT_TASKS"
    "Development|_ENVIRONMENTS_TASKS _DEVTOOLS_TASKS _AI_TASKS"
    "Software|_SOFTWARE_TASKS _EDITORS_TASKS _TERMINALS_TASKS _BROWSERS_TASKS _SECURITY_TASKS _VPNS_TASKS _PASSWORDS_TASKS _AUTHENTICATORS_TASKS _HWKEYS_TASKS _MEDIA_TASKS _MESSAGING_TASKS _PRODUCTIVITY_TASKS _FONTS_TASKS"
    "UI and Theming|_UI_TASKS _APPEARANCE_TASKS _APPTHEMES_TASKS"
    "Virtualization|_VIRTUALIZATION_TASKS"
)

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

health::_check_group() {
    local group_label="$1"
    shift
    local arr_names=($@)
    local total=0 installed=0
    local arr_name task label desc_var check_fn apply_fn status_fn

    for arr_name in "${arr_names[@]}"; do
        local -n tasks_ref="$arr_name"
        for task in "${tasks_ref[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            [[ "$apply_fn" == *"::run" ]] && continue
            total=$((total + 1))
            "$check_fn" && installed=$((installed + 1))
        done
    done

    if [[ $installed -eq $total ]]; then
        log::ok "${group_label}: ${installed}/${total}"
    else
        log::warn "${group_label}: ${installed}/${total}"
    fi
}

health::run() {
    local cpu_usage disk_usage mem_info uptime_str

    log::info "Running system health check"
    log::break

    cpu_usage="$(top -bn1 | grep '%Cpu' | awk '{printf "%.1f%%", 100 - $8}')"
    mem_info="$(free --mebi | awk '/^Mem:/ {printf "%.1fGi / %.1fGi (%.1f%%)", $3/1024, $2/1024, ($3/$2)*100}')"
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

    log::info "Task summary"
    local group group_label arr_names
    for group in "${_HEALTH_GROUPS[@]}"; do
        IFS='|' read -r group_label arr_names <<< "$group"
        health::_check_group "$group_label" $arr_names
    done

    ui::return_or_exit
}
