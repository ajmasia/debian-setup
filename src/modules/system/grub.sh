# GRUB bootloader configuration task

[[ -n "${_MOD_GRUB_LOADED:-}" ]] && return 0
_MOD_GRUB_LOADED=1

_GRUB_LABEL="Configure GRUB"
_GRUB_DESC="Configure GRUB resolution and background image."

_GRUB_CONF="/etc/default/grub"
_GRUB_CFG="/boot/grub/grub.cfg"
_GRUB_DEBIAN_THEME="/etc/grub.d/05_debian_theme"

_grub::gfxmode_set() {
    [[ -f "$_GRUB_CONF" ]] || return 1
    grep -q '^GRUB_GFXMODE=' "$_GRUB_CONF" 2>/dev/null || return 1
    local value
    value="$(grep -oP '^GRUB_GFXMODE=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
    value="${value//\"/}"
    [[ -n "$value" && "$value" != "auto" ]]
}

_grub::debian_theme_disabled() {
    [[ -f "$_GRUB_DEBIAN_THEME" && ! -x "$_GRUB_DEBIAN_THEME" ]]
}

_GRUB_SILENT_PARAMS=("quiet" "loglevel=0" "systemd.show_status=false" "vt.global_cursor_default=0")

_grub::silent_enabled() {
    [[ -f "$_GRUB_CONF" ]] || return 1
    local param
    for param in "${_GRUB_SILENT_PARAMS[@]}"; do
        grep -qF "$param" "$_GRUB_CONF" 2>/dev/null || return 1
    done
}

grub::check() {
    _grub::gfxmode_set
}

grub::status() {
    local issues=()
    _grub::gfxmode_set || issues+=("default resolution")
    if [[ -f "$_GRUB_DEBIAN_THEME" && -x "$_GRUB_DEBIAN_THEME" ]]; then
        issues+=("Debian theme active")
    fi
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

grub::apply() {
    local choice

    while true; do
        local gfxmode_ok=false
        _grub::gfxmode_set && gfxmode_ok=true

        ui::clear_content
        log::nav "System Essentials > GRUB"
        log::break

        log::info "GRUB bootloader configuration"

        # Show current GFXMODE
        local current_gfx="auto"
        if [[ -f "$_GRUB_CONF" ]]; then
            local raw
            raw="$(grep -oP '^GRUB_GFXMODE=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
            raw="${raw//\"/}"
            [[ -n "$raw" ]] && current_gfx="$raw"
        fi
        if $gfxmode_ok; then
            log::ok "Resolution: ${current_gfx}"
        else
            log::warn "Resolution: ${current_gfx} (default)"
        fi

        # Show payload
        if grep -q '^GRUB_GFXPAYLOAD_LINUX=keep' "$_GRUB_CONF" 2>/dev/null; then
            log::ok "Boot resolution: inherited"
        elif $gfxmode_ok; then
            log::warn "Boot resolution: native (not inherited)"
        fi

        # Show Debian theme status
        local theme_disabled=false
        [[ -f "$_GRUB_DEBIAN_THEME" && ! -x "$_GRUB_DEBIAN_THEME" ]] && theme_disabled=true

        if $theme_disabled; then
            log::ok "Debian theme: disabled"
        elif [[ -f "$_GRUB_DEBIAN_THEME" ]]; then
            log::warn "Debian theme: active"
        fi

        # Show silent boot status
        local silent_on=false
        _grub::silent_enabled && silent_on=true
        if $silent_on; then
            log::ok "Silent boot: enabled"
        else
            log::warn "Silent boot: disabled (kernel messages visible)"
        fi

        log::break

        local payload_on=false
        grep -q '^GRUB_GFXPAYLOAD_LINUX=keep' "$_GRUB_CONF" 2>/dev/null && payload_on=true

        local options=()
        options+=("Change resolution")
        if $gfxmode_ok && ! $payload_on; then
            options+=("Keep resolution during boot")
        fi
        if $payload_on; then
            options+=("Use native resolution during boot")
        fi
        if ! $theme_disabled && [[ -f "$_GRUB_DEBIAN_THEME" ]]; then
            options+=("Disable Debian theme")
        fi
        if $theme_disabled; then
            options+=("Enable Debian theme")
        fi
        if ! $silent_on; then
            options+=("Enable silent boot")
        else
            options+=("Disable silent boot")
        fi
        if $gfxmode_ok || $theme_disabled || $payload_on || $silent_on; then
            options+=("Restore defaults")
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
            "Change resolution")
                _grub::change_resolution
                ;;
            "Keep resolution during boot")
                _grub::set_payload keep
                ;;
            "Use native resolution during boot")
                _grub::set_payload remove
                ;;
            "Disable Debian theme")
                _grub::disable_debian_theme
                ;;
            "Enable Debian theme")
                _grub::enable_debian_theme
                ;;
            "Enable silent boot")
                _grub::set_silent enable
                ;;
            "Disable silent boot")
                _grub::set_silent disable
                ;;
            "Restore defaults")
                _grub::restore_defaults
                ;;
        esac
    done
}

_GRUB_COMMON_RESOLUTIONS=("1024x768" "1280x1024" "1440x900" "1680x1050" "1920x1080" "1920x1200" "2560x1440" "3840x2160")
_GRUB_RECOMMENDED="1920x1080"

_grub::detect_resolutions() {
    local mode_file
    for mode_file in /sys/class/drm/card*/*/modes; do
        [[ -f "$mode_file" ]] || continue
        cat "$mode_file"
    done | sort -t'x' -k1 -rn -k2 -rn | uniq
}

_grub::change_resolution() {
    local options=()
    local detected common mode
    detected="$(_grub::detect_resolutions)"

    if [[ -n "$detected" ]]; then
        for common in "${_GRUB_COMMON_RESOLUTIONS[@]}"; do
            if printf '%s\n' "$detected" | grep -qxF "$common"; then
                if [[ "$common" == "$_GRUB_RECOMMENDED" ]]; then
                    options+=("${common} (recommended)")
                else
                    options+=("$common")
                fi
            fi
        done
    fi

    if [[ ${#options[@]} -eq 0 ]]; then
        options+=("1024x768" "1440x900" "1920x1080 (recommended)" "1920x1200")
    fi
    options+=("Custom")

    local res_choice
    res_choice="$(gum::choose \
        --header "Select GRUB resolution:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${options[@]}")"

    if [[ -z "$res_choice" ]]; then
        return
    fi

    local resolution
    if [[ "$res_choice" == "Custom" ]]; then
        resolution="$(gum::input \
            --header "Enter resolution:" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. 1920x1080")"

        if [[ -z "$resolution" ]]; then
            return
        fi

        if ! [[ "$resolution" =~ ^[0-9]+x[0-9]+$ ]]; then
            log::error "Invalid format (expected WIDTHxHEIGHT, e.g. 1920x1080)"
            return
        fi
    else
        resolution="${res_choice% (recommended)}"
    fi

    log::break
    log::info "Setting GRUB_GFXMODE to ${resolution}"
    ui::flush_input
    if grep -q '^#\?GRUB_GFXMODE=' "$_GRUB_CONF" 2>/dev/null; then
        sudo sed -i "s/^#\\?GRUB_GFXMODE=.*/GRUB_GFXMODE=\"${resolution}\"/" "$_GRUB_CONF" </dev/tty
    else
        printf 'GRUB_GFXMODE="%s"\n' "$resolution" | sudo tee -a "$_GRUB_CONF" > /dev/null
    fi
    log::ok "GRUB_GFXMODE set to ${resolution}"

    _grub::update
}

_grub::set_payload() {
    log::break
    ui::flush_input
    if [[ "$1" == "keep" ]]; then
        log::info "Setting GRUB_GFXPAYLOAD_LINUX to keep"
        if grep -q '^#\?GRUB_GFXPAYLOAD_LINUX=' "$_GRUB_CONF" 2>/dev/null; then
            sudo sed -i 's/^#\?GRUB_GFXPAYLOAD_LINUX=.*/GRUB_GFXPAYLOAD_LINUX=keep/' "$_GRUB_CONF" </dev/tty
        else
            printf 'GRUB_GFXPAYLOAD_LINUX=keep\n' | sudo tee -a "$_GRUB_CONF" > /dev/null
        fi
        log::ok "Boot will use GRUB resolution"
    else
        if grep -q '^GRUB_GFXPAYLOAD_LINUX=' "$_GRUB_CONF" 2>/dev/null; then
            log::info "Removing GRUB_GFXPAYLOAD_LINUX"
            sudo sed -i '/^GRUB_GFXPAYLOAD_LINUX=/d' "$_GRUB_CONF" </dev/tty
            log::ok "Boot will use native resolution"
        fi
    fi

    _grub::update
}

_grub::disable_debian_theme() {
    log::break
    log::info "Disabling Debian GRUB theme"
    ui::flush_input
    sudo chmod -x "$_GRUB_DEBIAN_THEME" </dev/tty
    log::ok "Debian theme disabled"

    _grub::update
}

_grub::enable_debian_theme() {
    log::break
    log::info "Enabling Debian GRUB theme"
    ui::flush_input
    sudo chmod +x "$_GRUB_DEBIAN_THEME" </dev/tty
    log::ok "Debian theme enabled"

    _grub::update
}

_grub::set_silent() {
    log::break
    ui::flush_input
    if [[ "$1" == "enable" ]]; then
        log::info "Enabling silent boot"
        local param
        for param in "${_GRUB_SILENT_PARAMS[@]}"; do
            if ! grep -qF "$param" "$_GRUB_CONF" 2>/dev/null; then
                sudo sed -i "s/^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${param}\"/" "$_GRUB_CONF" </dev/tty
            fi
        done
        sudo sed -i 's/  */ /g' "$_GRUB_CONF" </dev/tty
        log::ok "Silent boot enabled"
    else
        log::info "Disabling silent boot"
        local param
        for param in "${_GRUB_SILENT_PARAMS[@]}"; do
            if grep -qF "$param" "$_GRUB_CONF" 2>/dev/null; then
                sudo sed -i "s/ ${param}//g" "$_GRUB_CONF" </dev/tty
            fi
        done
        log::ok "Silent boot disabled"
    fi

    _grub::update
}

_grub::restore_defaults() {
    log::break
    log::info "Restoring GRUB defaults"
    ui::flush_input
    if grep -q '^GRUB_GFXMODE=' "$_GRUB_CONF" 2>/dev/null; then
        sudo sed -i '/^GRUB_GFXMODE=/d' "$_GRUB_CONF" </dev/tty
        log::ok "GRUB_GFXMODE removed"
    fi
    if grep -q '^GRUB_GFXPAYLOAD_LINUX=' "$_GRUB_CONF" 2>/dev/null; then
        sudo sed -i '/^GRUB_GFXPAYLOAD_LINUX=/d' "$_GRUB_CONF" </dev/tty
        log::ok "GRUB_GFXPAYLOAD_LINUX removed"
    fi
    if [[ -f "$_GRUB_DEBIAN_THEME" && ! -x "$_GRUB_DEBIAN_THEME" ]]; then
        sudo chmod +x "$_GRUB_DEBIAN_THEME" </dev/tty
        log::ok "Debian theme re-enabled"
    fi
    if _grub::silent_enabled; then
        local param
        for param in "${_GRUB_SILENT_PARAMS[@]}"; do
            sudo sed -i "s/ ${param}//g" "$_GRUB_CONF" </dev/tty
        done
        log::ok "Silent boot disabled"
    fi

    _grub::update
}

_grub::update() {
    log::info "Updating GRUB"
    ui::flush_input
    if sudo update-grub </dev/tty; then
        log::ok "GRUB updated"
    else
        log::error "Failed to update GRUB"
    fi
}
