# GRUB bootloader configuration task

[[ -n "${_MOD_GRUB_LOADED:-}" ]] && return 0
_MOD_GRUB_LOADED=1

_GRUB_LABEL="Configure GRUB"
_GRUB_DESC="Configure GRUB resolution and background image."

_GRUB_CONF="/etc/default/grub"
_GRUB_CFG="/boot/grub/grub.cfg"

_grub::gfxmode_set() {
    [[ -f "$_GRUB_CONF" ]] || return 1
    grep -q '^GRUB_GFXMODE=' "$_GRUB_CONF" 2>/dev/null || return 1
    local value
    value="$(grep -oP '^GRUB_GFXMODE=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
    value="${value//\"/}"
    [[ -n "$value" && "$value" != "auto" ]]
}

_grub::background_clean() {
    [[ -f "$_GRUB_CFG" ]] || return 0
    ! grep -q 'background_image' "$_GRUB_CFG" 2>/dev/null
}

grub::check() {
    _grub::gfxmode_set && _grub::background_clean
}

grub::status() {
    local issues=()
    _grub::gfxmode_set || issues+=("default resolution")
    _grub::background_clean || issues+=("background image set")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

grub::apply() {
    local choice

    while true; do
        local gfxmode_ok=false bg_clean=true
        _grub::gfxmode_set && gfxmode_ok=true
        _grub::background_clean || bg_clean=false

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

        # Show current BACKGROUND
        if $bg_clean; then
            log::ok "Background: clean"
        else
            local bg_path
            bg_path="$(grep -oP 'background_image \K\S+' "$_GRUB_CFG" 2>/dev/null | head -1 || true)"
            log::warn "Background: ${bg_path:-detected}"
        fi

        log::break

        local options=()
        options+=("Change resolution")
        if ! $bg_clean; then
            options+=("Remove background")
        fi
        if $gfxmode_ok || ! $bg_clean; then
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
            "Remove background")
                _grub::remove_background
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

_grub::remove_background() {
    log::break
    log::info "Removing GRUB background"
    ui::flush_input
    if grep -q '^#\?GRUB_BACKGROUND=' "$_GRUB_CONF" 2>/dev/null; then
        sudo sed -i 's/^#\?GRUB_BACKGROUND=.*/GRUB_BACKGROUND=""/' "$_GRUB_CONF" </dev/tty
    else
        printf 'GRUB_BACKGROUND=""\n' | sudo tee -a "$_GRUB_CONF" > /dev/null
    fi
    log::ok "GRUB_BACKGROUND overridden"

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
    if grep -q '^GRUB_BACKGROUND=' "$_GRUB_CONF" 2>/dev/null; then
        sudo sed -i '/^GRUB_BACKGROUND=/d' "$_GRUB_CONF" </dev/tty
        log::ok "GRUB_BACKGROUND removed"
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
