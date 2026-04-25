# Mullvad Browser task

[[ -n "${_MOD_MULLVAD_LOADED:-}" ]] && return 0
_MOD_MULLVAD_LOADED=1

_MULLVAD_LABEL="Configure Mullvad Browser"
_MULLVAD_DESC="Install Mullvad Browser."

_MULLVAD_GPG_URL="https://repository.mullvad.net/deb/mullvad-keyring.asc"
_MULLVAD_GPG_KEY="/usr/share/keyrings/mullvad-keyring.asc"
_MULLVAD_SOURCES="/etc/apt/sources.list.d/mullvad.list"

_mullvad::is_installed() {
    dpkg -l mullvad-browser 2>/dev/null | grep -q '^ii'
}

mullvad::check() {
    _mullvad::is_installed
}

mullvad::status() {
    _mullvad::is_installed || printf 'not installed'
}

mullvad::apply() {
    local choice

    while true; do
        local installed=false
        _mullvad::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Browsers > Mullvad Browser"
        log::break

        log::info "Mullvad Browser"

        if $installed; then
            local version
            version="$(dpkg -l mullvad-browser 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Mullvad Browser: ${version}"
        else
            log::warn "Mullvad Browser (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Mullvad Browser")
        else
            options+=("Install Mullvad Browser")
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
            "Install Mullvad Browser")
                log::break
                _mullvad::install
                ;;
            "Remove Mullvad Browser")
                log::break
                _mullvad::remove
                ;;
        esac
    done
}

_mullvad::install() {
    log::info "Adding Mullvad repository"
    ui::flush_input

    if ! sudo curl -fsSLo "$_MULLVAD_GPG_KEY" "$_MULLVAD_GPG_URL" </dev/tty; then
        log::error "Failed to download Mullvad GPG key"
        ui::return_or_exit
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

    log::info "Installing Mullvad Browser"
    if sudo apt-get install -y mullvad-browser </dev/tty; then
        hash -r
        log::ok "Mullvad Browser installed"
    else
        log::error "Failed to install Mullvad Browser"
    fi
    ui::return_or_exit
}

_mullvad::remove() {
    log::info "Removing Mullvad Browser"
    ui::flush_input
    if sudo apt-get remove -y mullvad-browser </dev/tty; then
        hash -r
        log::ok "Mullvad Browser removed"
    else
        log::error "Failed to remove Mullvad Browser"
        ui::return_or_exit
        return
    fi

    # Only clean repo/key if Mullvad VPN is not installed
    if ! dpkg -l mullvad-vpn 2>/dev/null | grep -q '^ii'; then
        if [[ -f "$_MULLVAD_SOURCES" ]]; then
            sudo rm -f "$_MULLVAD_SOURCES"
            log::ok "Mullvad repository removed"
        fi
        if [[ -f "$_MULLVAD_GPG_KEY" ]]; then
            sudo rm -f "$_MULLVAD_GPG_KEY"
            log::ok "Mullvad GPG key removed"
        fi
    else
        log::info "Keeping Mullvad repository (Mullvad VPN still installed)"
    fi
    ui::return_or_exit
}
