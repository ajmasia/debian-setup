# Plymouth boot splash configuration task

[[ -n "${_MOD_PLYMOUTH_LOADED:-}" ]] && return 0
_MOD_PLYMOUTH_LOADED=1

_PLYMOUTH_LABEL="Configure Plymouth"
_PLYMOUTH_DESC="Configure Plymouth boot splash with spinner theme."

_PLYMOUTH_PACKAGES=("plymouth" "plymouth-themes")
_PLYMOUTH_SUPPORTED_THEMES=("spinner" "bgrt" "bgrt-luks")
_PLYMOUTH_BGRT_LUKS_DIR="/usr/share/plymouth/themes/bgrt-luks"
_PLYMOUTH_BGRT_LUKS_CONF="${_PLYMOUTH_BGRT_LUKS_DIR}/bgrt-luks.plymouth"

_PLYMOUTH_COMMUNITY_REPO="https://github.com/adi1090x/plymouth-themes.git"
_PLYMOUTH_THEMES_DIR="/usr/share/plymouth/themes"
_PLYMOUTH_COMMUNITY_LIST="${SCRIPT_DIR}/packages/plymouth/themes.txt"

_plymouth::installed() {
    local pkg
    for pkg in "${_PLYMOUTH_PACKAGES[@]}"; do
        dpkg -l "$pkg" 2>/dev/null | grep -q '^ii' || return 1
    done
    return 0
}

_plymouth::community_installed() {
    local dir_name="$1"
    [[ -d "${_PLYMOUTH_THEMES_DIR}/${dir_name}" ]] \
        && [[ -f "${_PLYMOUTH_THEMES_DIR}/${dir_name}/${dir_name}.plymouth" ]]
}

_plymouth::community_count() {
    local total=0 inst=0 dir_name label pack
    while IFS='|' read -r dir_name label pack || [[ -n "$dir_name" ]]; do
        [[ -z "$dir_name" || "$dir_name" == \#* ]] && continue
        total=$((total + 1))
        if _plymouth::community_installed "$dir_name"; then
            inst=$((inst + 1))
        fi
    done < "$_PLYMOUTH_COMMUNITY_LIST"
    printf '%s %s' "$inst" "$total"
}

_plymouth::current_theme() {
    local current
    current="$(plymouth-set-default-theme 2>/dev/null || true)"
    if [[ -z "$current" && -f /etc/plymouth/plymouthd.conf ]]; then
        current="$(grep -oP '^\s*Theme=\K.*' /etc/plymouth/plymouthd.conf 2>/dev/null || true)"
    fi
    printf '%s' "$current"
}

_plymouth::theme_active() {
    local current theme
    current="$(_plymouth::current_theme)"
    for theme in "${_PLYMOUTH_SUPPORTED_THEMES[@]}"; do
        [[ "$current" == "$theme" ]] && return 0
    done
    # Check installed community themes
    if _plymouth::community_installed "$current"; then
        return 0
    fi
    return 1
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
            current="$(_plymouth::current_theme)"
            if $theme_ok; then
                log::ok "Theme: ${current}"
            else
                log::warn "Theme: ${current:-none} (not a supported theme)"
            fi
            if $grub_ok; then
                log::ok "GRUB: splash enabled"
            else
                log::warn "GRUB: splash not enabled"
            fi

            local c_counts c_inst c_total
            c_counts="$(_plymouth::community_count)"
            c_inst="${c_counts% *}"
            c_total="${c_counts#* }"
            if [[ "$c_inst" -eq "$c_total" ]]; then
                log::ok "Community themes: ${c_inst}/${c_total}"
            else
                log::warn "Community themes: ${c_inst}/${c_total}"
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
            options+=("Change theme")
            options+=("Install community themes")
            if [[ "$c_inst" -gt 0 ]]; then
                options+=("Remove community themes")
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
            "Change theme")
                _plymouth::select_theme
                ;;
            "Install community themes")
                log::break
                _plymouth::install_community
                ;;
            "Remove community themes")
                log::break
                _plymouth::remove_community
                ;;
            "Remove Plymouth")
                log::break
                _plymouth::remove
                ;;
        esac
    done
}

_plymouth::ensure_bgrt_luks() {
    [[ -f "$_PLYMOUTH_BGRT_LUKS_CONF" ]] && return 0

    log::info "Creating bgrt-luks theme"
    ui::flush_input
    sudo mkdir -p "$_PLYMOUTH_BGRT_LUKS_DIR" </dev/tty

    local conf
    conf="$(cat <<'THEME'
[Plymouth Theme]
Name=BGRT LUKS
Description=BGRT theme with manufacturer logo visible during LUKS password prompt
ModuleName=two-step

[two-step]
Font=Cantarell 12
TitleFont=Cantarell Light 30
ImageDir=/usr/share/plymouth/themes/spinner
DialogHorizontalAlignment=.5
DialogVerticalAlignment=.7
TitleHorizontalAlignment=.5
TitleVerticalAlignment=.7
HorizontalAlignment=.5
VerticalAlignment=.7
WatermarkHorizontalAlignment=.5
WatermarkVerticalAlignment=.96
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
ProgressBarBackgroundColor=0x606060
ProgressBarForegroundColor=0xffffff
DialogClearsFirmwareBackground=false
MessageBelowAnimation=true

[boot-up]
UseEndAnimation=false
UseFirmwareBackground=true

[shutdown]
UseEndAnimation=false
UseFirmwareBackground=true

[reboot]
UseEndAnimation=false
UseFirmwareBackground=true

[updates]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Installing Updates...
SubTitle=Do not turn off your computer

[system-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading System...
SubTitle=Do not turn off your computer

[firmware-upgrade]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Upgrading Firmware...
SubTitle=Do not turn off your computer

[system-reset]
SuppressMessages=true
ProgressBarShowPercentComplete=true
UseProgressBar=true
Title=Resetting System...
SubTitle=Do not turn off your computer
THEME
)"
    printf '%s\n' "$conf" | sudo tee "$_PLYMOUTH_BGRT_LUKS_CONF" > /dev/null
    log::ok "bgrt-luks theme created"

    # If theme was already selected but files were missing, rebuild initramfs
    local current
    current="$(_plymouth::current_theme)"
    if [[ "$current" == "bgrt-luks" ]]; then
        log::info "Rebuilding initramfs with bgrt-luks theme"
        if sudo update-initramfs -u </dev/tty; then
            log::ok "Initramfs updated"
        else
            log::error "Failed to update initramfs"
        fi
    fi
}

_plymouth::select_theme() {
    local current
    current="$(_plymouth::current_theme)"

    # gum menu will push header offscreen — force full repaint on return
    _UI_DIRTY=1

    local theme_options=(
        "spinner — Generic loading animation"
        "bgrt — Manufacturer logo (UEFI)"
        "bgrt-luks — Manufacturer logo visible during LUKS"
    )

    # Add installed community themes
    local dir_name label pack
    while IFS='|' read -r dir_name label pack || [[ -n "$dir_name" ]]; do
        [[ -z "$dir_name" || "$dir_name" == \#* ]] && continue
        if _plymouth::community_installed "$dir_name"; then
            theme_options+=("${dir_name} — ${label} (community)")
        fi
    done < "$_PLYMOUTH_COMMUNITY_LIST"

    local theme_choice
    if [[ ${#theme_options[@]} -gt 5 ]]; then
        theme_choice="$(gum::filter \
            --height 12 \
            --header "Select Plymouth theme (current: ${current:-none}):" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            "${theme_options[@]}")"
    else
        theme_choice="$(gum::choose \
            --header "Select Plymouth theme (current: ${current:-none}):" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${theme_options[@]}")"
    fi

    if [[ -z "$theme_choice" ]]; then
        return
    fi

    local theme="${theme_choice%% —*}"

    log::break

    # Ensure bgrt-luks theme files exist before any check
    if [[ "$theme" == "bgrt-luks" ]]; then
        _plymouth::ensure_bgrt_luks || return
    fi

    if [[ "$theme" == "$current" ]]; then
        log::ok "Theme already set to ${theme}"
        ui::return_or_exit
        return
    fi

    log::info "Setting theme to ${theme}"
    ui::flush_input
    if sudo plymouth-set-default-theme "$theme" </dev/tty; then
        log::ok "Theme set to ${theme}"
    else
        log::error "Failed to set theme"
        ui::return_or_exit
        return
    fi

    log::info "Updating initramfs"
    if sudo update-initramfs -u </dev/tty; then
        log::ok "Initramfs updated"
    else
        log::error "Failed to update initramfs"
    fi
    ui::return_or_exit
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
    # Set theme if not a supported one
    if ! _plymouth::theme_active; then
        local target="${_PLYMOUTH_SUPPORTED_THEMES[0]}"
        log::info "Setting theme to ${target}"
        ui::flush_input
        if sudo plymouth-set-default-theme "$target" </dev/tty; then
            log::ok "Theme set to ${target}"
        else
            log::error "Failed to set theme"
            ui::return_or_exit
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
    ui::return_or_exit
}

# ── Community themes ───────────────────────────────────

_plymouth::install_community() {
    local dir_name label pack
    local pending_labels=()
    local -A meta_map=()

    while IFS='|' read -r dir_name label pack || [[ -n "$dir_name" ]]; do
        [[ -z "$dir_name" || "$dir_name" == \#* ]] && continue
        if ! _plymouth::community_installed "$dir_name"; then
            local display="${label} (${dir_name})"
            pending_labels+=("$display")
            meta_map["$display"]="${dir_name}|${label}|${pack}"
        fi
    done < "$_PLYMOUTH_COMMUNITY_LIST"

    if [[ ${#pending_labels[@]} -eq 0 ]]; then
        log::ok "All community themes already installed"
        ui::return_or_exit
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select themes to install (space to select, enter to confirm):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"
    ui::spin_start "Cloning community themes repository..."
    if ! git clone --depth 1 "$_PLYMOUTH_COMMUNITY_REPO" "$tmpdir" 2>/dev/null; then
        ui::spin_stop
        log::error "Failed to clone repository"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi
    ui::spin_stop
    log::ok "Repository cloned"

    local display t_dir t_label t_pack count=0
    while IFS= read -r display; do
        IFS='|' read -r t_dir t_label t_pack <<< "${meta_map[$display]}"
        local src="${tmpdir}/${t_pack}/${t_dir}"
        local dest="${_PLYMOUTH_THEMES_DIR}/${t_dir}"

        if [[ ! -d "$src" ]]; then
            log::error "Theme '${t_dir}' not found in ${t_pack}"
            continue
        fi

        log::info "Installing ${t_label}"
        ui::flush_input
        sudo cp -r "$src" "$dest" </dev/tty
        sudo update-alternatives --install \
            "${_PLYMOUTH_THEMES_DIR}/default.plymouth" default.plymouth \
            "${dest}/${t_dir}.plymouth" 100 </dev/tty 2>/dev/null || true
        log::ok "${t_label} installed"
        count=$((count + 1))
    done <<< "$selected"

    rm -rf "$tmpdir"

    if [[ $count -gt 0 ]]; then
        log::ok "${count} theme(s) installed — use 'Change theme' to apply"
    fi
    ui::return_or_exit
}

_plymouth::remove_community() {
    local dir_name label pack
    local installed_labels=()
    local -A meta_map=()

    while IFS='|' read -r dir_name label pack || [[ -n "$dir_name" ]]; do
        [[ -z "$dir_name" || "$dir_name" == \#* ]] && continue
        if _plymouth::community_installed "$dir_name"; then
            local display="${label} (${dir_name})"
            installed_labels+=("$display")
            meta_map["$display"]="${dir_name}|${label}"
        fi
    done < "$_PLYMOUTH_COMMUNITY_LIST"

    if [[ ${#installed_labels[@]} -eq 0 ]]; then
        log::ok "No community themes installed"
        ui::return_or_exit
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select themes to remove (space to select, enter to confirm):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${installed_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display t_dir t_label count=0 needs_initramfs=false
    while IFS= read -r display; do
        IFS='|' read -r t_dir t_label <<< "${meta_map[$display]}"
        local dest="${_PLYMOUTH_THEMES_DIR}/${t_dir}"

        # Check before removing if this is the active theme
        local current
        current="$(_plymouth::current_theme)"

        log::info "Removing ${t_label}"
        ui::flush_input
        sudo update-alternatives --remove default.plymouth \
            "${dest}/${t_dir}.plymouth" </dev/tty 2>/dev/null || true
        sudo rm -rf "$dest" </dev/tty
        log::ok "${t_label} removed"
        count=$((count + 1))

        if [[ "$current" == "$t_dir" ]]; then
            log::info "Active theme removed — falling back to spinner"
            ui::flush_input
            sudo plymouth-set-default-theme spinner </dev/tty || true
            needs_initramfs=true
        fi
    done <<< "$selected"

    if $needs_initramfs; then
        log::info "Updating initramfs"
        ui::flush_input
        if sudo update-initramfs -u </dev/tty; then
            log::ok "Initramfs updated"
        else
            log::error "Failed to update initramfs"
        fi
    elif [[ $count -gt 0 ]]; then
        log::ok "${count} theme(s) removed"
    fi
    ui::return_or_exit
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

    # Remove installed community themes
    local dir_name label pack
    while IFS='|' read -r dir_name label pack || [[ -n "$dir_name" ]]; do
        [[ -z "$dir_name" || "$dir_name" == \#* ]] && continue
        if _plymouth::community_installed "$dir_name"; then
            log::info "Removing community theme: ${label}"
            ui::flush_input
            sudo update-alternatives --remove default.plymouth \
                "${_PLYMOUTH_THEMES_DIR}/${dir_name}/${dir_name}.plymouth" </dev/tty 2>/dev/null || true
            sudo rm -rf "${_PLYMOUTH_THEMES_DIR}/${dir_name}" </dev/tty
            log::ok "${label} removed"
        fi
    done < "$_PLYMOUTH_COMMUNITY_LIST"

    # Remove custom bgrt-luks theme if present
    if [[ -d "$_PLYMOUTH_BGRT_LUKS_DIR" ]]; then
        log::info "Removing bgrt-luks theme"
        ui::flush_input
        sudo rm -rf "$_PLYMOUTH_BGRT_LUKS_DIR" </dev/tty
        log::ok "bgrt-luks theme removed"
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
    ui::return_or_exit
}
