# Backports kernel management task

[[ -n "${_MOD_KERNEL_LOADED:-}" ]] && return 0
_MOD_KERNEL_LOADED=1

_KERNEL_LABEL="Configure backports kernel"
_KERNEL_DESC="Install or revert the Linux kernel from Debian backports."

_kernel::has_backports() {
    grep -rq "backports" /etc/apt/sources.list.d/ 2>/dev/null \
        || grep -q "backports" /etc/apt/sources.list 2>/dev/null
}

_kernel::has_bpo() {
    dpkg -l 'linux-image-*' 2>/dev/null | grep '^ii' | grep -q 'bpo'
}

_kernel::_codename() {
    # shellcheck source=/etc/os-release
    . /etc/os-release 2>/dev/null
    printf '%s' "${VERSION_CODENAME:-}"
}

_kernel::_bpo_pkgs() {
    dpkg -l 'linux-image-*' 'linux-headers-*' 2>/dev/null \
        | grep '^ii' | grep 'bpo' | awk '{print $2}'
}

_kernel::_running_version() {
    uname -r
}

kernel::check() {
    _kernel::has_bpo
}

kernel::status() {
    if _kernel::has_bpo; then
        printf 'backports kernel active'
    else
        printf 'stable kernel'
    fi
}

kernel::apply() {
    local choice

    while true; do
        local bpo_ok=false backports_available=false
        _kernel::has_bpo && bpo_ok=true
        _kernel::has_backports && backports_available=true

        ui::clear_content
        log::nav "System core > Backports kernel"
        log::break

        log::info "Current kernel: $(_kernel::_running_version)"

        if $bpo_ok; then
            log::ok "Backports kernel: installed"
            local bpo_pkgs
            bpo_pkgs="$(_kernel::_bpo_pkgs)"
            if [[ -n "$bpo_pkgs" ]]; then
                local pkg
                while IFS= read -r pkg; do
                    log::ok "  ${pkg}"
                done <<< "$bpo_pkgs"
            fi
        else
            log::info "Running stable kernel"
        fi

        log::break

        local options=()
        if $bpo_ok; then
            options+=("Revert to stable kernel")
        elif $backports_available; then
            options+=("Install backports kernel")
        else
            log::warn "Backports not enabled in APT sources"
        fi
        options+=("Back" "Exit")

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
            "Install backports kernel")
                log::break
                _kernel::_install_bpo
                return
                ;;
            "Revert to stable kernel")
                log::break
                _kernel::_revert_stable
                return
                ;;
        esac
    done
}

_kernel::_install_bpo() {
    local codename
    codename="$(_kernel::_codename)"
    if [[ -z "$codename" ]]; then
        log::error "Could not detect Debian codename"
        return
    fi

    log::info "Installing latest kernel from ${codename}-backports"
    ui::flush_input
    if sudo apt install -y -t "${codename}-backports" linux-image-amd64 linux-headers-amd64 </dev/tty; then
        hash -r
        log::ok "Backports kernel installed (reboot required)"
    else
        log::error "Failed to install backports kernel"
    fi
}

_kernel::_revert_stable() {
    log::info "Reinstalling stable kernel meta-packages"
    ui::flush_input
    if sudo apt install -y linux-image-amd64 linux-headers-amd64 </dev/tty; then
        hash -r
        log::ok "Stable kernel meta-packages reinstalled"
    else
        log::error "Failed to reinstall stable kernel"
        return
    fi

    # Filter out packages matching the running kernel to avoid bricking
    local running
    running="$(uname -r)"
    local bpo_pkgs
    bpo_pkgs="$(_kernel::_bpo_pkgs)"
    if [[ -n "$bpo_pkgs" ]]; then
        local pkgs=() skipped=()
        while IFS= read -r pkg; do
            if [[ "$pkg" == *"$running"* ]]; then
                skipped+=("$pkg")
            else
                pkgs+=("$pkg")
            fi
        done <<< "$bpo_pkgs"

        if [[ ${#skipped[@]} -gt 0 ]]; then
            log::warn "Skipping running kernel packages: ${skipped[*]}"
            log::warn "Reboot into stable kernel first, then remove them"
        fi

        if [[ ${#pkgs[@]} -gt 0 ]]; then
            log::info "Removing backports kernel packages: ${pkgs[*]}"
            ui::flush_input
            if sudo apt remove -y "${pkgs[@]}" </dev/tty; then
                hash -r
                log::ok "Backports kernel packages removed"
            else
                log::error "Failed to remove backports kernel packages"
            fi
        fi
    fi

    log::break
    log::ok "Reboot to use the stable kernel"
}
