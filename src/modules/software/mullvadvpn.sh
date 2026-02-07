# Mullvad VPN task

[[ -n "${_MOD_MULLVADVPN_LOADED:-}" ]] && return 0
_MOD_MULLVADVPN_LOADED=1

_MULLVADVPN_LABEL="Configure Mullvad VPN"
_MULLVADVPN_DESC="Install Mullvad VPN client."

_mullvadvpn::is_installed() {
    dpkg -l mullvad-vpn 2>/dev/null | grep -q '^ii'
}

mullvadvpn::check() {
    _mullvadvpn::is_installed
}

mullvadvpn::status() {
    _mullvadvpn::is_installed || printf 'not installed'
}

mullvadvpn::apply() {
    local choice

    while true; do
        local installed=false
        _mullvadvpn::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > VPN > Mullvad VPN"
        log::break

        log::info "Mullvad VPN"

        if $installed; then
            local version
            version="$(dpkg -l mullvad-vpn 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Mullvad VPN: ${version}"
        else
            log::warn "Mullvad VPN (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Mullvad VPN")
        else
            options+=("Install Mullvad VPN")
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
            "Install Mullvad VPN")
                log::break
                _mullvadvpn::install
                ;;
            "Remove Mullvad VPN")
                log::break
                _mullvadvpn::remove
                ;;
        esac
    done
}

_mullvadvpn::install() {
    # Add Mullvad repo only if not already present (shared with Mullvad Browser)
    if [[ ! -f "$_MULLVAD_SOURCES" ]]; then
        log::info "Adding Mullvad repository"
        ui::flush_input

        if ! sudo curl -fsSLo "$_MULLVAD_GPG_KEY" "$_MULLVAD_GPG_URL" </dev/tty; then
            log::error "Failed to download Mullvad GPG key"
            return
        fi
        sudo chmod 644 "$_MULLVAD_GPG_KEY"

        local arch
        arch="$(dpkg --print-architecture)"
        printf 'deb [signed-by=%s arch=%s] https://repository.mullvad.net/deb/stable stable main\n' \
            "$_MULLVAD_GPG_KEY" "$arch" | sudo tee "$_MULLVAD_SOURCES" > /dev/null
        log::ok "Repository added"

        log::info "Updating package lists"
        if ! sudo apt-get update </dev/tty; then
            log::warn "apt-get update finished with warnings"
        fi
    else
        log::info "Mullvad repository already configured"
        ui::flush_input
    fi

    log::info "Installing Mullvad VPN"
    if sudo apt-get install -y mullvad-vpn </dev/tty; then
        hash -r
        log::ok "Mullvad VPN installed"
    else
        log::error "Failed to install Mullvad VPN"
    fi
}

_mullvadvpn::remove() {
    log::info "Removing Mullvad VPN"
    ui::flush_input
    if sudo apt-get remove -y mullvad-vpn </dev/tty; then
        hash -r
        log::ok "Mullvad VPN removed"
    else
        log::error "Failed to remove Mullvad VPN"
        return
    fi

    # Only clean repo/key if Mullvad Browser is not installed
    if ! dpkg -l mullvad-browser 2>/dev/null | grep -q '^ii'; then
        if [[ -f "$_MULLVAD_SOURCES" ]]; then
            sudo rm -f "$_MULLVAD_SOURCES"
            log::ok "Mullvad repository removed"
        fi
        if [[ -f "$_MULLVAD_GPG_KEY" ]]; then
            sudo rm -f "$_MULLVAD_GPG_KEY"
            log::ok "Mullvad GPG key removed"
        fi
    else
        log::info "Keeping Mullvad repository (Mullvad Browser still installed)"
    fi
}
