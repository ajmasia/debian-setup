# QEMU/KVM + Virtual Machine Manager task

[[ -n "${_MOD_QEMU_LOADED:-}" ]] && return 0
_MOD_QEMU_LOADED=1

_QEMU_LABEL="Configure QEMU/KVM"
_QEMU_DESC="Install QEMU/KVM with Virtual Machine Manager."

_QEMU_PACKAGES="qemu-system-x86 libvirt-daemon-system libvirt-clients virt-manager virtinst bridge-utils ovmf"
_QEMU_GROUPS="libvirt kvm"

# --- Detection helpers ---

_qemu::is_installed() {
    dpkg -l qemu-system-x86 2>/dev/null | grep -q '^ii' &&
    dpkg -l libvirt-daemon-system 2>/dev/null | grep -q '^ii' &&
    dpkg -l virt-manager 2>/dev/null | grep -q '^ii'
}

_qemu::kvm_supported() {
    [[ -e /dev/kvm ]]
}

_qemu::user_in_groups() {
    local grp
    for grp in $_QEMU_GROUPS; do
        id -nG "$USER" | grep -qw "$grp" || return 1
    done
    return 0
}

_qemu::libvirtd_active() {
    systemctl is-active --quiet libvirtd 2>/dev/null
}

_qemu::libvirtd_enabled() {
    systemctl is-enabled --quiet libvirtd 2>/dev/null
}

# virsh without sudo — works if user is in libvirt group, fails gracefully otherwise
_qemu::default_net_active() {
    virsh net-info default 2>/dev/null | grep -q 'Active:.*yes'
}

_qemu::default_net_autostart() {
    virsh net-info default 2>/dev/null | grep -q 'Autostart:.*yes'
}

# --- Public API ---

qemu::check() {
    _qemu::is_installed &&
    _qemu::user_in_groups &&
    _qemu::libvirtd_active &&
    _qemu::libvirtd_enabled
}

qemu::status() {
    local issues=()
    _qemu::is_installed || issues+=("not installed")
    if _qemu::is_installed; then
        _qemu::user_in_groups || issues+=("user not in groups")
        _qemu::libvirtd_active || issues+=("libvirtd not active")
    fi
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

qemu::apply() {
    local choice

    while true; do
        local installed=false in_groups=false svc_active=false svc_enabled=false
        local net_active=false net_autostart=false kvm_ok=false

        _qemu::is_installed && installed=true
        _qemu::kvm_supported && kvm_ok=true

        if $installed; then
            _qemu::user_in_groups && in_groups=true
            _qemu::libvirtd_active && svc_active=true
            _qemu::libvirtd_enabled && svc_enabled=true
            _qemu::default_net_active && net_active=true
            _qemu::default_net_autostart && net_autostart=true
        fi

        ui::clear_content
        log::nav "Virtualization > QEMU/KVM"
        log::break

        log::info "QEMU/KVM with Virtual Machine Manager"

        # KVM hardware support
        if $kvm_ok; then
            log::ok "KVM hardware acceleration available"
        else
            log::warn "KVM not available (/dev/kvm missing — check BIOS virtualization)"
        fi

        if $installed; then
            local qemu_ver
            qemu_ver="$(qemu-system-x86_64 --version 2>/dev/null | head -1 || true)"
            log::ok "QEMU: ${qemu_ver}"

            # Groups
            if $in_groups; then
                log::ok "User ${USER} in groups: ${_QEMU_GROUPS}"
            else
                local missing_groups=()
                local grp
                for grp in $_QEMU_GROUPS; do
                    id -nG "$USER" | grep -qw "$grp" || missing_groups+=("$grp")
                done
                log::warn "User ${USER} missing groups: ${missing_groups[*]}"
            fi

            # Service
            if $svc_active && $svc_enabled; then
                log::ok "libvirtd: active, enabled"
            elif $svc_active; then
                log::warn "libvirtd: active but not enabled"
            elif $svc_enabled; then
                log::warn "libvirtd: enabled but not active"
            else
                log::warn "libvirtd: not active, not enabled"
            fi

            # Default network (only show if user can query virsh)
            if $in_groups || $net_active; then
                if $net_active && $net_autostart; then
                    log::ok "Default network: active, autostart"
                elif $net_active; then
                    log::warn "Default network: active but no autostart"
                else
                    log::warn "Default network: not active"
                fi
            else
                log::warn "Default network: log out and back in to check (group change pending)"
            fi
        else
            log::warn "QEMU/KVM (not installed)"
        fi

        log::break

        # Build dynamic options
        local options=()

        if $installed; then
            if ! $in_groups; then
                options+=("Add user to groups")
            fi
            if ! $svc_active || ! $svc_enabled; then
                options+=("Enable libvirtd service")
            fi
            if ! $net_active || ! $net_autostart; then
                options+=("Enable default network")
            fi
            options+=("Remove QEMU/KVM")
        else
            options+=("Install QEMU/KVM")
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
            "Install QEMU/KVM")
                log::break
                _qemu::install
                ;;
            "Add user to groups")
                log::break
                _qemu::add_user_to_groups
                ;;
            "Enable libvirtd service")
                log::break
                _qemu::enable_service
                ;;
            "Enable default network")
                log::break
                _qemu::enable_network
                ;;
            "Remove QEMU/KVM")
                log::break
                _qemu::remove
                ;;
        esac
    done
}

# --- Internal actions ---

_qemu::install() {
    log::info "Installing QEMU/KVM and Virtual Machine Manager"
    ui::flush_input

    # shellcheck disable=SC2086
    if sudo apt-get install -y $_QEMU_PACKAGES </dev/tty; then
        hash -r
        log::ok "QEMU/KVM packages installed"
        log::break

        _qemu::add_user_to_groups
        _qemu::enable_service
        _qemu::enable_network
    else
        log::error "Failed to install QEMU/KVM packages"
    fi
}

_qemu::add_user_to_groups() {
    local grp
    for grp in $_QEMU_GROUPS; do
        if ! id -nG "$USER" | grep -qw "$grp"; then
            log::info "Adding ${USER} to ${grp} group"
            ui::flush_input
            if sudo usermod -aG "$grp" "$USER" </dev/tty; then
                log::ok "Added to ${grp}"
            else
                log::error "Failed to add to ${grp}"
            fi
        fi
    done
    log::break
    log::warn "Log out and back in for group changes to take effect"
}

_qemu::enable_service() {
    log::info "Enabling libvirtd service"
    ui::flush_input

    if ! _qemu::libvirtd_enabled; then
        sudo systemctl enable libvirtd </dev/tty
    fi

    if ! _qemu::libvirtd_active; then
        sudo systemctl start libvirtd </dev/tty
    fi

    if _qemu::libvirtd_active && _qemu::libvirtd_enabled; then
        log::ok "libvirtd: active and enabled"
    else
        log::error "Failed to enable libvirtd"
    fi
}

_qemu::enable_network() {
    log::info "Enabling default network"
    ui::flush_input

    if ! sudo virsh net-info default &>/dev/null; then
        # Network not defined — try to define it from template
        if [[ -f /usr/share/libvirt/networks/default.xml ]]; then
            sudo virsh net-define /usr/share/libvirt/networks/default.xml </dev/tty || true
        else
            log::warn "Default network not defined and template not found"
            return
        fi
    fi

    local active=false autostart=false
    sudo virsh net-info default 2>/dev/null | grep -q 'Active:.*yes' && active=true
    sudo virsh net-info default 2>/dev/null | grep -q 'Autostart:.*yes' && autostart=true

    if ! $active; then
        sudo virsh net-start default </dev/tty || true
    fi

    if ! $autostart; then
        sudo virsh net-autostart default </dev/tty || true
    fi

    # Recheck
    active=false
    autostart=false
    sudo virsh net-info default 2>/dev/null | grep -q 'Active:.*yes' && active=true
    sudo virsh net-info default 2>/dev/null | grep -q 'Autostart:.*yes' && autostart=true

    if $active && $autostart; then
        log::ok "Default network: active with autostart"
    else
        log::warn "Default network may need manual configuration"
    fi
}

_qemu::remove() {
    log::info "Removing QEMU/KVM packages"
    ui::flush_input

    # Stop network and service first
    sudo virsh net-destroy default 2>/dev/null </dev/tty || true
    sudo virsh net-undefine default 2>/dev/null </dev/tty || true
    sudo systemctl stop libvirtd 2>/dev/null </dev/tty || true
    sudo systemctl disable libvirtd 2>/dev/null </dev/tty || true

    # shellcheck disable=SC2086
    if sudo apt-get remove -y $_QEMU_PACKAGES </dev/tty; then
        hash -r
        log::ok "QEMU/KVM removed"
    else
        log::error "Failed to remove QEMU/KVM packages"
    fi
}
