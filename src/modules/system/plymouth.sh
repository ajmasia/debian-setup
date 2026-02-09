# Plymouth boot splash configuration task

[[ -n "${_MOD_PLYMOUTH_LOADED:-}" ]] && return 0
_MOD_PLYMOUTH_LOADED=1

_PLYMOUTH_LABEL="Configure Plymouth"
_PLYMOUTH_DESC="Configure Plymouth boot splash with spinner theme."

_PLYMOUTH_PACKAGES=("plymouth" "plymouth-themes")
_PLYMOUTH_THEME="spinner"

_plymouth::installed() {
    local pkg
    for pkg in "${_PLYMOUTH_PACKAGES[@]}"; do
        dpkg -l "$pkg" 2>/dev/null | grep -q '^ii' || return 1
    done
    return 0
}

_plymouth::theme_active() {
    local current
    current="$(plymouth-set-default-theme 2>/dev/null || true)"
    [[ "$current" == "$_PLYMOUTH_THEME" ]]
}

_plymouth::grub_has_splash() {
    if [[ -f /etc/default/grub ]]; then
        grep -q 'splash' /etc/default/grub 2>/dev/null
    else
        return 1
    fi
}

plymouth::check() {
    _plymouth::installed && _plymouth::theme_active && _plymouth::grub_has_splash
}

plymouth::status() {
    local issues=()
    _plymouth::installed || issues+=("not installed")
    _plymouth::installed && ! _plymouth::theme_active && issues+=("theme not set")
    _plymouth::installed && ! _plymouth::grub_has_splash && issues+=("splash not in GRUB")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

plymouth::apply() {
    local choice

    while true; do
        local installed=false theme_ok=false grub_ok=false
        _plymouth::installed && installed=true
        _plymouth::theme_active && theme_ok=true
        _plymouth::grub_has_splash && grub_ok=true

        ui::clear_content
        log::nav "System Essentials > Plymouth"
        log::break

        log::info "Plymouth boot splash"

        if $installed; then
            log::ok "Plymouth: installed"
            local current
            current="$(plymouth-set-default-theme 2>/dev/null || true)"
            if $theme_ok; then
                log::ok "Theme: ${current}"
            else
                log::warn "Theme: ${current:-none} (expected ${_PLYMOUTH_THEME})"
            fi
            if $grub_ok; then
                log::ok "GRUB: splash enabled"
            else
                log::warn "GRUB: splash not enabled"
            fi
        else
            log::warn "Plymouth (not installed)"
        fi

        log::break

        local options=()

        if ! $installed; then
            options+=("Install and configure Plymouth")
        else
            if ! $theme_ok || ! $grub_ok; then
                options+=("Configure Plymouth")
            fi
            options+=("Remove Plymouth")
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
            "Install and configure Plymouth")
                log::break
                _plymouth::install
                _plymouth::configure
                ;;
            "Configure Plymouth")
                log::break
                _plymouth::configure
                ;;
            "Remove Plymouth")
                log::break
                _plymouth::remove
                ;;
        esac
    done
}

_plymouth::install() {
    log::info "Installing Plymouth"
    ui::flush_input
    if sudo apt-get install -y "${_PLYMOUTH_PACKAGES[@]}" </dev/tty; then
        hash -r
        log::ok "Plymouth installed"
    else
        log::error "Failed to install Plymouth"
    fi
}

_plymouth::configure() {
    # Set theme
    if ! _plymouth::theme_active; then
        log::info "Setting theme to ${_PLYMOUTH_THEME}"
        ui::flush_input
        if sudo plymouth-set-default-theme "$_PLYMOUTH_THEME" </dev/tty; then
            log::ok "Theme set to ${_PLYMOUTH_THEME}"
        else
            log::error "Failed to set theme"
            return
        fi
    fi

    # Enable splash in GRUB
    if ! _plymouth::grub_has_splash; then
        log::info "Enabling splash in GRUB"
        ui::flush_input
        sudo sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 splash"/' /etc/default/grub </dev/tty
        # Clean up double spaces
        sudo sed -i 's/  */ /g' /etc/default/grub
        log::ok "Splash added to GRUB_CMDLINE_LINUX_DEFAULT"
    fi

    # Update GRUB and initramfs
    log::info "Updating GRUB"
    ui::flush_input
    if sudo update-grub </dev/tty; then
        log::ok "GRUB updated"
    else
        log::error "Failed to update GRUB"
    fi

    log::info "Updating initramfs"
    if sudo update-initramfs -u </dev/tty; then
        log::ok "Initramfs updated"
    else
        log::error "Failed to update initramfs"
    fi
}

_plymouth::remove() {
    # Remove splash from GRUB
    if _plymouth::grub_has_splash; then
        log::info "Removing splash from GRUB"
        ui::flush_input
        sudo sed -i 's/ splash//g' /etc/default/grub </dev/tty
        log::ok "Splash removed from GRUB"

        log::info "Updating GRUB"
        if sudo update-grub </dev/tty; then
            log::ok "GRUB updated"
        else
            log::error "Failed to update GRUB"
        fi
    fi

    log::info "Removing Plymouth"
    ui::flush_input
    if sudo apt-get remove -y "${_PLYMOUTH_PACKAGES[@]}" </dev/tty; then
        hash -r
        log::ok "Plymouth removed"
    else
        log::error "Failed to remove Plymouth"
    fi

    log::info "Updating initramfs"
    if sudo update-initramfs -u </dev/tty; then
        log::ok "Initramfs updated"
    else
        log::error "Failed to update initramfs"
    fi
}
