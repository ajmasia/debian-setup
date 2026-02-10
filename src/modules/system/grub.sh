# GRUB bootloader configuration task

[[ -n "${_MOD_GRUB_LOADED:-}" ]] && return 0
_MOD_GRUB_LOADED=1

_GRUB_LABEL="Configure GRUB"
_GRUB_DESC="Configure GRUB resolution and background image."

_GRUB_CONF="/etc/default/grub"

_grub::gfxmode_set() {
    [[ -f "$_GRUB_CONF" ]] || return 1
    grep -q '^GRUB_GFXMODE=' "$_GRUB_CONF" 2>/dev/null || return 1
    local value
    value="$(grep -oP '^GRUB_GFXMODE=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
    value="${value//\"/}"
    [[ -n "$value" && "$value" != "auto" ]]
}

_grub::background_clean() {
    [[ -f "$_GRUB_CONF" ]] || return 0
    if grep -q '^GRUB_BACKGROUND=' "$_GRUB_CONF" 2>/dev/null; then
        local value
        value="$(grep -oP '^GRUB_BACKGROUND=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
        value="${value//\"/}"
        [[ -z "$value" ]]
    else
        return 0
    fi
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
            local current_bg
            current_bg="$(grep -oP '^GRUB_BACKGROUND=\K.*' "$_GRUB_CONF" 2>/dev/null || true)"
            current_bg="${current_bg//\"/}"
            log::warn "Background: ${current_bg}"
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

_grub::change_resolution() {
    local res_choice
    res_choice="$(gum::choose \
        --header "Select GRUB resolution:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "1280x800 — Large text, very readable" \
        "1440x900 — Good balance" \
        "1920x1200 — High resolution" \
        "Custom")"

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
        resolution="${res_choice%% —*}"
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
        log::ok "GRUB_BACKGROUND cleared"
    else
        log::ok "No GRUB_BACKGROUND to remove"
        return
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
