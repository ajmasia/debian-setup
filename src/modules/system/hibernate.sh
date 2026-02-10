# Suspend-then-hibernate configuration task

[[ -n "${_MOD_HIBERNATE_LOADED:-}" ]] && return 0
_MOD_HIBERNATE_LOADED=1

_HIBERNATE_LABEL="Configure Hibernate"
_HIBERNATE_DESC="Configure swap and suspend-then-hibernate."

_HIBERNATE_DEFAULT_SWAPFILE="/swapfile"
_HIBERNATE_SLEEP_CONF="/etc/systemd/sleep.conf.d/hibernate.conf"
_HIBERNATE_LOGIND_CONF="/etc/systemd/logind.conf.d/hibernate.conf"
_HIBERNATE_RESUME_CONF="/etc/initramfs-tools/conf.d/resume"
_HIBERNATE_DELAY="30min"

# Populated by _hibernate::detect_swap()
_HIBERNATE_SWAP_DEVICE=""
_HIBERNATE_SWAP_TYPE=""
_HIBERNATE_SWAP_SIZE_KIB=0

# ── Helpers ─────────────────────────────────────────────

_hibernate::ram_kib() {
    awk '/^MemTotal:/ {print $2}' /proc/meminfo
}

_hibernate::ram_gb() {
    awk '/^MemTotal:/ {gb = $2 / 1048576; printf "%d", (gb == int(gb)) ? gb : int(gb) + 1}' /proc/meminfo
}

# Parse /proc/swaps for a usable (non-zram) swap device.
# Sets _HIBERNATE_SWAP_DEVICE, _HIBERNATE_SWAP_TYPE, _HIBERNATE_SWAP_SIZE_KIB.
# Returns 1 if no usable swap found.
_hibernate::detect_swap() {
    _HIBERNATE_SWAP_DEVICE=""
    _HIBERNATE_SWAP_TYPE=""
    _HIBERNATE_SWAP_SIZE_KIB=0

    local dev type size _rest
    while read -r dev type size _rest; do
        # Skip header line
        [[ "$dev" == "Filename" ]] && continue
        # Skip zram devices
        [[ "$dev" == /dev/zram* ]] && continue

        _HIBERNATE_SWAP_DEVICE="$dev"
        _HIBERNATE_SWAP_TYPE="$type"
        _HIBERNATE_SWAP_SIZE_KIB="$size"
        return 0
    done < /proc/swaps

    return 1
}

_hibernate::swap_sufficient() {
    local ram_kib
    ram_kib="$(_hibernate::ram_kib)"
    [[ "$_HIBERNATE_SWAP_SIZE_KIB" -ge "$ram_kib" ]]
}

_hibernate::swap_is_partition() {
    [[ "$_HIBERNATE_SWAP_TYPE" == "partition" ]]
}

_hibernate::swap_uuid() {
    lsblk -no UUID "$_HIBERNATE_SWAP_DEVICE" 2>/dev/null
}

_hibernate::swap_size_gb() {
    if [[ "$_HIBERNATE_SWAP_SIZE_KIB" -gt 0 ]]; then
        echo $(( (_HIBERNATE_SWAP_SIZE_KIB + 1048575) / 1048576 ))
    else
        echo 0
    fi
}

_hibernate::root_uuid() {
    findmnt -no UUID /
}

_hibernate::swap_offset() {
    if [[ -f "$_HIBERNATE_SWAP_DEVICE" ]]; then
        sudo filefrag -v "$_HIBERNATE_SWAP_DEVICE" 2>/dev/null | awk 'NR==4{gsub(/\.\./,""); print $4}'
    fi
}

_hibernate::grub_has_resume() {
    grep -q 'resume=' /etc/default/grub 2>/dev/null
}

_hibernate::resume_configured() {
    [[ -f "$_HIBERNATE_RESUME_CONF" ]]
}

_hibernate::sleep_configured() {
    [[ -f "$_HIBERNATE_SLEEP_CONF" ]]
}

_hibernate::logind_configured() {
    [[ -f "$_HIBERNATE_LOGIND_CONF" ]]
}

# ── Public API ──────────────────────────────────────────

hibernate::check() {
    local has_swap=false
    _hibernate::detect_swap && has_swap=true
    $has_swap \
        && _hibernate::swap_sufficient \
        && _hibernate::grub_has_resume \
        && _hibernate::resume_configured \
        && _hibernate::sleep_configured \
        && _hibernate::logind_configured
}

hibernate::status() {
    local issues=()
    local has_swap=false
    _hibernate::detect_swap && has_swap=true

    if ! $has_swap; then
        issues+=("no swap")
    elif ! _hibernate::swap_sufficient; then
        local swap_gb
        swap_gb="$(_hibernate::swap_size_gb)"
        issues+=("swap too small (${swap_gb}G)")
    fi

    _hibernate::grub_has_resume || issues+=("no resume in GRUB")
    _hibernate::resume_configured || issues+=("no initramfs resume")
    _hibernate::sleep_configured || issues+=("sleep not configured")
    _hibernate::logind_configured || issues+=("lid switch not configured")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

# ── Wizard ──────────────────────────────────────────────

hibernate::apply() {
    local choice

    while true; do
        local has_swap=false grub_ok=false resume_ok=false sleep_ok=false logind_ok=false
        _hibernate::detect_swap && has_swap=true
        _hibernate::grub_has_resume && grub_ok=true
        _hibernate::resume_configured && resume_ok=true
        _hibernate::sleep_configured && sleep_ok=true
        _hibernate::logind_configured && logind_ok=true

        ui::clear_content
        log::nav "System Essentials > Hibernate"
        log::break

        log::info "Suspend-then-hibernate"

        # Swap status
        if $has_swap; then
            local swap_gb
            swap_gb="$(_hibernate::swap_size_gb)"
            local ram_gb
            ram_gb="$(_hibernate::ram_gb)"
            local type_label="file"
            _hibernate::swap_is_partition && type_label="partition"

            if _hibernate::swap_sufficient; then
                log::ok "Swap ${type_label}: ${_HIBERNATE_SWAP_DEVICE} (${swap_gb}G, active)"
            else
                log::warn "Swap ${type_label}: ${_HIBERNATE_SWAP_DEVICE} (${swap_gb}G < ${ram_gb}G RAM)"
            fi
        else
            log::warn "Swap: none detected (zram excluded)"
        fi

        # Zram coexistence info
        if grep -q '/dev/zram' /proc/swaps 2>/dev/null; then
            log::ok "Zram: active (high priority for daily use)"
        fi

        # GRUB resume
        if $grub_ok; then
            log::ok "GRUB: resume configured"
        else
            log::warn "GRUB: resume not configured"
        fi

        # Initramfs resume
        if $resume_ok; then
            log::ok "Initramfs: resume configured"
        else
            log::warn "Initramfs: resume not configured"
        fi

        # systemd-sleep
        if $sleep_ok; then
            log::ok "Sleep: suspend-then-hibernate enabled"
        else
            log::warn "Sleep: not configured"
        fi

        # logind lid switch
        if $logind_ok; then
            log::ok "Lid switch: suspend-then-hibernate"
        else
            log::warn "Lid switch: not configured"
        fi

        log::break

        local options=()

        if ! $has_swap || ! _hibernate::swap_sufficient || ! $grub_ok || ! $resume_ok || ! $sleep_ok || ! $logind_ok; then
            options+=("Configure all")
        fi

        if $grub_ok || $resume_ok || $sleep_ok || $logind_ok || [[ -f "$_HIBERNATE_DEFAULT_SWAPFILE" ]]; then
            options+=("Remove hibernate config")
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
            "Configure all")
                log::break
                _hibernate::configure
                ;;
            "Remove hibernate config")
                log::break
                _hibernate::remove
                ;;
        esac
    done
}

# ── Create swapfile ────────────────────────────────────

_hibernate::create_swapfile() {
    local ram_gb swap_size
    ram_gb="$(_hibernate::ram_gb)"
    swap_size="${ram_gb}"

    log::info "RAM detected: ${ram_gb}G — swap needs to be >= RAM for hibernate"

    local size_choice
    size_choice="$(gum::choose \
        --header "Swap file size:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${ram_gb}G (match RAM)" \
        "Custom")"

    if [[ "$size_choice" == "Custom" ]]; then
        swap_size="$(gum::input \
            --header "Enter swap size in GB (>= ${ram_gb}):" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "e.g. ${ram_gb}")"
    fi

    if [[ -z "$swap_size" ]]; then
        log::warn "No size selected, skipped"
        return 1
    fi

    # Remove existing swapfile if present
    if [[ -f "$_HIBERNATE_DEFAULT_SWAPFILE" ]]; then
        log::info "Removing existing swap file"
        ui::flush_input
        sudo /sbin/swapoff "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty 2>/dev/null || true
        sudo rm -f "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
    fi

    log::info "Creating ${swap_size}G swap file (this may take a moment)"
    ui::flush_input
    if ! sudo fallocate -l "${swap_size}G" "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty; then
        log::error "Failed to create swap file"
        return 1
    fi
    sudo chmod 600 "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
    sudo mkswap "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
    log::ok "Swap file created: ${swap_size}G"

    # Activate with low priority (zram keeps priority 100)
    sudo /sbin/swapon -p 1 "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
    log::ok "Swap file activated (priority 1)"

    # Add to fstab if not present
    if ! grep -qF "$_HIBERNATE_DEFAULT_SWAPFILE" /etc/fstab 2>/dev/null; then
        printf '%s none swap sw,pri=1 0 0\n' "$_HIBERNATE_DEFAULT_SWAPFILE" | sudo tee -a /etc/fstab > /dev/null
        log::ok "Added to /etc/fstab (priority 1)"
    fi

    # Re-detect swap after creation
    _hibernate::detect_swap || true
}

# ── Configure GRUB ─────────────────────────────────────

_hibernate::configure_grub() {
    if _hibernate::grub_has_resume; then
        log::ok "GRUB resume already configured"
        return
    fi

    local resume_uuid resume_offset=""

    if _hibernate::swap_is_partition; then
        resume_uuid="$(_hibernate::swap_uuid)"
        if [[ -z "$resume_uuid" ]]; then
            log::error "Could not determine swap partition UUID"
            return
        fi
        log::info "Adding resume to GRUB (swap partition UUID=${resume_uuid})"
    else
        resume_uuid="$(_hibernate::root_uuid)"
        ui::flush_input
        resume_offset="$(_hibernate::swap_offset)"
        if [[ -z "$resume_uuid" || -z "$resume_offset" ]]; then
            log::error "Could not determine root UUID or swap offset"
            return
        fi
        log::info "Adding resume to GRUB (UUID=${resume_uuid}, offset=${resume_offset})"
    fi

    local resume_params="resume=UUID=${resume_uuid}"
    [[ -n "$resume_offset" ]] && resume_params+=" resume_offset=${resume_offset}"

    ui::flush_input
    sudo sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"|GRUB_CMDLINE_LINUX_DEFAULT=\"\1 ${resume_params}\"|" /etc/default/grub </dev/tty
    # Clean up double spaces
    sudo sed -i 's/  */ /g' /etc/default/grub

    log::info "Updating GRUB"
    if sudo update-grub </dev/tty; then
        log::ok "GRUB updated with resume parameters"
    else
        log::error "Failed to update GRUB"
    fi
}

# ── Configure initramfs ───────────────────────────────

_hibernate::configure_initramfs() {
    if _hibernate::resume_configured; then
        log::ok "Initramfs resume already configured"
        return
    fi

    local resume_uuid

    if _hibernate::swap_is_partition; then
        resume_uuid="$(_hibernate::swap_uuid)"
    else
        resume_uuid="$(_hibernate::root_uuid)"
    fi

    if [[ -z "$resume_uuid" ]]; then
        log::error "Could not determine resume UUID"
        return
    fi

    log::info "Configuring initramfs resume"
    ui::flush_input
    printf 'RESUME=UUID=%s\n' "$resume_uuid" | sudo tee "$_HIBERNATE_RESUME_CONF" > /dev/null

    log::info "Updating initramfs"
    if sudo update-initramfs -u </dev/tty; then
        log::ok "Initramfs updated"
    else
        log::error "Failed to update initramfs"
    fi
}

# ── Configure ───────────────────────────────────────────

_hibernate::configure() {
    local ram_gb
    ram_gb="$(_hibernate::ram_gb)"

    # 1. Ensure usable swap exists
    local has_swap=false
    _hibernate::detect_swap && has_swap=true

    if $has_swap && _hibernate::swap_sufficient; then
        local swap_gb
        swap_gb="$(_hibernate::swap_size_gb)"
        local type_label="file"
        _hibernate::swap_is_partition && type_label="partition"
        log::ok "Using existing swap ${type_label}: ${_HIBERNATE_SWAP_DEVICE} (${swap_gb}G)"
    else
        if $has_swap; then
            local swap_gb
            swap_gb="$(_hibernate::swap_size_gb)"
            log::warn "Existing swap too small (${swap_gb}G < ${ram_gb}G RAM)"
        fi
        _hibernate::create_swapfile || return
    fi

    # 2. Configure GRUB resume
    _hibernate::configure_grub

    # 3. Configure initramfs resume
    _hibernate::configure_initramfs

    # 4. Configure systemd-sleep
    if ! _hibernate::sleep_configured; then
        log::info "Configuring suspend-then-hibernate (delay: ${_HIBERNATE_DELAY})"
        ui::flush_input
        sudo mkdir -p "$(dirname "$_HIBERNATE_SLEEP_CONF")" </dev/tty
        printf '[Sleep]\nAllowSuspendThenHibernate=yes\nHibernateDelaySec=%s\n' "$_HIBERNATE_DELAY" \
            | sudo tee "$_HIBERNATE_SLEEP_CONF" > /dev/null
        log::ok "systemd-sleep configured"
    else
        log::ok "systemd-sleep already configured"
    fi

    # 5. Configure logind lid switch
    if ! _hibernate::logind_configured; then
        log::info "Configuring lid switch to suspend-then-hibernate"
        ui::flush_input
        sudo mkdir -p "$(dirname "$_HIBERNATE_LOGIND_CONF")" </dev/tty
        printf '[Login]\nHandleLidSwitch=suspend-then-hibernate\nHandleLidSwitchExternalPower=suspend-then-hibernate\n' \
            | sudo tee "$_HIBERNATE_LOGIND_CONF" > /dev/null
        sudo systemctl restart systemd-logind </dev/tty 2>/dev/null || true
        log::ok "Lid switch configured"
    else
        log::ok "Lid switch already configured"
    fi

    log::break
    log::ok "Suspend-then-hibernate configured"
    log::info "Reboot recommended to activate resume parameters"
}

# ── Remove ──────────────────────────────────────────────

_hibernate::remove() {
    # Remove logind config
    if _hibernate::logind_configured; then
        log::info "Removing logind config"
        ui::flush_input
        sudo rm -f "$_HIBERNATE_LOGIND_CONF" </dev/tty
        sudo systemctl restart systemd-logind </dev/tty 2>/dev/null || true
        log::ok "Logind config removed"
    fi

    # Remove sleep config
    if _hibernate::sleep_configured; then
        log::info "Removing sleep config"
        ui::flush_input
        sudo rm -f "$_HIBERNATE_SLEEP_CONF" </dev/tty
        log::ok "Sleep config removed"
    fi

    # Remove initramfs resume
    if _hibernate::resume_configured; then
        log::info "Removing initramfs resume"
        ui::flush_input
        sudo rm -f "$_HIBERNATE_RESUME_CONF" </dev/tty
        log::info "Updating initramfs"
        sudo update-initramfs -u </dev/tty || true
        log::ok "Initramfs resume removed"
    fi

    # Remove GRUB resume
    if _hibernate::grub_has_resume; then
        log::info "Removing resume from GRUB"
        ui::flush_input
        sudo sed -i 's/ resume=UUID=[^ ]*//g; s/ resume_offset=[^ "]*//g' /etc/default/grub </dev/tty
        sudo sed -i 's/  */ /g' /etc/default/grub
        log::info "Updating GRUB"
        sudo update-grub </dev/tty || true
        log::ok "GRUB resume removed"
    fi

    # Only remove the default swapfile — never touch user's swap partitions
    if grep -qF "$_HIBERNATE_DEFAULT_SWAPFILE" /proc/swaps 2>/dev/null; then
        log::info "Deactivating swap file"
        ui::flush_input
        sudo /sbin/swapoff "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
        log::ok "Swap file deactivated"
    fi

    if [[ -f "$_HIBERNATE_DEFAULT_SWAPFILE" ]]; then
        log::info "Removing swap file"
        ui::flush_input
        sudo rm -f "$_HIBERNATE_DEFAULT_SWAPFILE" </dev/tty
        log::ok "Swap file removed"
    fi

    # Remove from fstab
    if grep -qF "$_HIBERNATE_DEFAULT_SWAPFILE" /etc/fstab 2>/dev/null; then
        log::info "Removing swap from fstab"
        ui::flush_input
        sudo sed -i "\|${_HIBERNATE_DEFAULT_SWAPFILE}|d" /etc/fstab </dev/tty
        log::ok "Removed from fstab"
    fi

    log::break
    log::ok "Hibernate configuration removed"
}
