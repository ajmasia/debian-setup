# Proton VPN task

[[ -n "${_MOD_PROTONVPN_LOADED:-}" ]] && return 0
_MOD_PROTONVPN_LOADED=1

_PROTONVPN_LABEL="Configure Proton VPN"
_PROTONVPN_DESC="Install Proton VPN client."
_PROTONVPN_REPO_DEB_URL="https://repo.protonvpn.com/debian/dists/stable/main/binary-all/protonvpn-stable-release_1.0.8_all.deb"

_protonvpn::is_installed() {
    dpkg -l proton-vpn-gnome-desktop 2>/dev/null | grep -q '^ii'
}

protonvpn::check() {
    _protonvpn::is_installed
}

protonvpn::status() {
    _protonvpn::is_installed || printf 'not installed'
}

protonvpn::apply() {
    local choice

    while true; do
        local installed=false
        _protonvpn::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > VPN > Proton VPN"
        log::break

        log::info "Proton VPN"

        if $installed; then
            local version
            version="$(dpkg -l proton-vpn-gnome-desktop 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Proton VPN: ${version}"
        else
            log::warn "Proton VPN (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Proton VPN")
        else
            options+=("Install Proton VPN")
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
            "Install Proton VPN")
                log::break
                _protonvpn::install
                ;;
            "Remove Proton VPN")
                log::break
                _protonvpn::remove
                ;;
        esac
    done
}

_protonvpn::install() {
    log::info "Downloading Proton VPN repository package"
    ui::flush_input

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$_PROTONVPN_REPO_DEB_URL"; then
        log::error "Failed to download Proton VPN repo package"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi

    log::info "Installing repository package"
    if ! sudo dpkg -i "$tmpfile" </dev/tty; then
        log::error "Failed to install repo package"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi
    rm -f "$tmpfile"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing Proton VPN"
    if sudo apt-get install -y proton-vpn-gnome-desktop </dev/tty; then
        hash -r
        log::ok "Proton VPN installed"
    else
        log::error "Failed to install Proton VPN"
    fi
    ui::return_or_exit
}

_protonvpn::remove() {
    log::info "Removing Proton VPN"
    ui::flush_input
    if sudo apt-get remove -y proton-vpn-gnome-desktop </dev/tty; then
        hash -r
        log::ok "Proton VPN removed"
    else
        log::error "Failed to remove Proton VPN"
        ui::return_or_exit
        return
    fi

    # Remove repo package
    if dpkg -l protonvpn-stable-release 2>/dev/null | grep -q '^ii'; then
        log::info "Removing Proton VPN repository"
        if sudo apt-get remove -y protonvpn-stable-release </dev/tty; then
            log::ok "Proton VPN repository removed"
        fi
    fi
    ui::return_or_exit
}
