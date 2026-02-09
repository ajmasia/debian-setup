# System upgrade task

[[ -n "${_MOD_UPGRADE_LOADED:-}" ]] && return 0
_MOD_UPGRADE_LOADED=1

_UPGRADE_LABEL="Configure System Upgrade"
_UPGRADE_DESC="Update and upgrade all system packages."

_upgrade::upgradable_count() {
    local count
    count="$(apt list --upgradable 2>/dev/null | grep -c 'upgradable' || true)"
    printf '%s' "${count:-0}"
}

upgrade::check() {
    [[ "$(_upgrade::upgradable_count)" -eq 0 ]]
}

upgrade::status() {
    local count
    count="$(_upgrade::upgradable_count)"
    if [[ "$count" -gt 0 ]]; then
        printf '%s packages upgradable' "$count"
    fi
}

upgrade::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Package Managers > System Upgrade"
        log::break

        log::info "System upgrade"

        local count
        count="$(_upgrade::upgradable_count)"

        if [[ "$count" -eq 0 ]]; then
            log::ok "System is up to date"
        else
            log::warn "${count} package(s) upgradable"
        fi

        log::break

        local options=()
        options+=("Update & upgrade" "Back" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${options[@]}")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            "Update & upgrade")
                log::break
                _upgrade::run
                ;;
        esac
    done
}

_upgrade::run() {
    log::info "Updating package lists"
    ui::flush_input
    if sudo apt-get update </dev/tty; then
        log::ok "Package lists updated"
    else
        log::warn "apt-get update finished with warnings"
    fi

    log::break
    log::info "Upgrading packages"
    if sudo apt-get dist-upgrade -y </dev/tty; then
        log::ok "Packages upgraded"
    else
        log::error "Failed to upgrade packages"
        ui::return_or_exit
        return
    fi

    log::break
    log::info "Removing unused packages"
    if sudo apt-get autoremove -y </dev/tty; then
        log::ok "Unused packages removed"
    else
        log::warn "autoremove finished with warnings"
    fi

    log::break
    log::ok "System upgrade complete"
    ui::return_or_exit
}
