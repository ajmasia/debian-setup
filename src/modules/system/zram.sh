# Zram swap configuration task

[[ -n "${_MOD_ZRAM_LOADED:-}" ]] && return 0
_MOD_ZRAM_LOADED=1

_ZRAM_LABEL="Enable zram swap"
_ZRAM_DESC="Installs zram-tools and configures compressed swap in RAM (zstd).
Improves performance on systems with limited memory."

zram::check() {
    systemctl is-enabled zramswap &>/dev/null
}

zram::apply() {
    # Check for existing swap and inform
    local swap_info
    swap_info="$(swapon --show 2>/dev/null)"
    if [[ -n "$swap_info" ]]; then
        log::warn "Active swap detected:"
        printf "%b%s%b\n" "${COLOR_OVERLAY1}" "$swap_info" "${COLOR_RESET}"
        log::break
    fi

    # Install zram-tools if needed
    if ! dpkg -s zram-tools &>/dev/null; then
        log::info "Installing zram-tools"
        ui::flush_input
        sudo apt install -y zram-tools
        log::ok "zram-tools installed"
        log::break
    fi

    # Select zram percentage
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
        percent="$(gum input \
            --header "Enter zram percentage (1-100):" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. 75")"
    fi

    if [[ -z "$percent" ]]; then
        log::warn "No percentage selected, skipped"
        return
    fi

    # Write config
    log::info "Configuring zram: ${percent}% RAM, zstd compression"
    ui::flush_input
    printf 'ALGO=zstd\nPERCENT=%s\n' "$percent" | sudo tee /etc/default/zramswap > /dev/null
    log::ok "zram configured"

    # Enable and restart service
    log::info "Enabling zramswap service"
    sudo systemctl enable --now zramswap
    sudo systemctl restart zramswap
    log::ok "zram swap active (${percent}% RAM, zstd)"
}
