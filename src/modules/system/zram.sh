# Zram swap configuration task

[[ -n "${_MOD_ZRAM_LOADED:-}" ]] && return 0
_MOD_ZRAM_LOADED=1

_ZRAM_LABEL="Configure Zram Swap"
_ZRAM_DESC="Manage compressed swap in RAM (zstd) via zram-tools."

_zram::installed() {
    dpkg -l zram-tools 2>/dev/null | grep -q '^ii'
}

_zram::enabled() {
    systemctl is-enabled zramswap &>/dev/null
}

_zram::current_percent() {
    if [[ -f /etc/default/zramswap ]]; then
        grep -oP 'PERCENT=\K[0-9]+' /etc/default/zramswap 2>/dev/null
    fi
}

zram::check() {
    _zram::installed && _zram::enabled
}

zram::status() {
    local issues=()
    _zram::installed || issues+=("not installed")
    _zram::installed && ! _zram::enabled && issues+=("not enabled")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

zram::apply() {
    local choice

    while true; do
        local installed=false enabled=false percent=""
        _zram::installed && installed=true
        _zram::enabled && enabled=true
        percent="$(_zram::current_percent)"

        ui::clear_content
        log::nav "System core > Configure zram swap"
        log::break

        log::info "Current zram configuration"

        if $installed; then
            log::ok "zram-tools: installed"
        else
            log::warn "zram-tools: not installed"
        fi

        if $enabled; then
            log::ok "zramswap service: enabled"
            if [[ -n "$percent" ]]; then
                log::ok "Size: ${percent}% of RAM (zstd)"
            fi
        elif $installed; then
            log::warn "zramswap service: disabled"
        fi

        # Show active swap
        local swap_info
        swap_info="$(/sbin/swapon --show 2>/dev/null || true)"
        if [[ -n "$swap_info" ]]; then
            log::break
            log::info "Active swap devices"
            printf "%b%s%b\n" "${COLOR_OVERLAY1}" "$swap_info" "${COLOR_RESET}"
        fi

        log::break

        local options=()
        if ! $installed; then
            options+=("Install and enable zram")
        elif ! $enabled; then
            options+=("Enable zram")
            options+=("Remove zram-tools")
        else
            options+=("Change zram percentage")
            options+=("Disable zram")
            options+=("Remove zram-tools")
        fi
        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select a change to apply:" \
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
            "Install and enable zram")
                log::break
                log::info "Installing zram-tools"
                ui::flush_input
                if sudo apt install -y zram-tools </dev/tty; then
                    hash -r
                    log::ok "zram-tools installed"
                else
                    log::error "Failed to install zram-tools"
                    continue
                fi
                _zram::_configure_and_start
                return
                ;;
            "Enable zram")
                log::break
                _zram::_configure_and_start
                return
                ;;
            "Change zram percentage")
                log::break
                _zram::_configure_and_start
                return
                ;;
            "Disable zram")
                log::break
                log::info "Disabling zramswap service"
                ui::flush_input
                if sudo systemctl disable --now zramswap </dev/tty; then
                    log::ok "zram disabled"
                    return
                else
                    log::error "Failed to disable zram"
                fi
                ;;
            "Remove zram-tools")
                log::break
                log::info "Removing zram-tools"
                ui::flush_input
                if sudo apt remove -y zram-tools </dev/tty; then
                    hash -r
                    log::ok "zram-tools removed"
                    return
                else
                    log::error "Failed to remove zram-tools"
                fi
                ;;
        esac
    done
}

_zram::_configure_and_start() {
    local percent
    percent="$(gum::choose \
        --header "Select zram size (% of RAM):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "25" \
        "50" \
        "Custom")"

    if [[ "$percent" == "Custom" ]]; then
        percent="$(gum::input \
            --header "Enter zram percentage (1-100):" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. 75")"
    fi

    if [[ -z "$percent" ]]; then
        log::warn "No percentage selected, skipped"
        return
    fi

    log::info "Configuring zram: ${percent}% RAM, zstd compression"
    ui::flush_input
    printf 'ALGO=zstd\nPERCENT=%s\n' "$percent" | sudo tee /etc/default/zramswap > /dev/null

    log::info "Enabling zramswap service"
    if ! sudo systemctl enable --now zramswap </dev/tty; then
        log::error "Failed to enable zramswap"
        return
    fi
    if sudo systemctl restart zramswap; then
        log::ok "zram swap active (${percent}% RAM, zstd)"
    else
        log::warn "zramswap enabled but restart failed"
    fi
}
