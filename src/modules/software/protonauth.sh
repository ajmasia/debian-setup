# Proton Authenticator task

[[ -n "${_MOD_PROTONAUTH_LOADED:-}" ]] && return 0
_MOD_PROTONAUTH_LOADED=1

_PROTONAUTH_LABEL="Configure Proton Authenticator"
_PROTONAUTH_DESC="Install Proton Authenticator."
_PROTONAUTH_DEB_URL="https://proton.me/download/PassDesktop/linux/x64/ProtonAuthenticator.deb"

_protonauth::is_installed() {
    dpkg -l proton-authenticator 2>/dev/null | grep -q '^ii'
}

protonauth::check() {
    _protonauth::is_installed
}

protonauth::status() {
    _protonauth::is_installed || printf 'not installed'
}

protonauth::apply() {
    local choice

    while true; do
        local installed=false
        _protonauth::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Authenticators > Proton Authenticator"
        log::break

        log::info "Proton Authenticator"

        if $installed; then
            local version
            version="$(dpkg -l proton-authenticator 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Proton Authenticator: ${version}"
        else
            log::warn "Proton Authenticator (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Proton Authenticator")
        else
            options+=("Install Proton Authenticator")
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
            "Install Proton Authenticator")
                log::break
                _protonauth::install
                ;;
            "Remove Proton Authenticator")
                log::break
                _protonauth::remove
                ;;
        esac
    done
}

_protonauth::install() {
    log::info "Downloading Proton Authenticator"
    ui::flush_input

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$_PROTONAUTH_DEB_URL"; then
        log::error "Failed to download Proton Authenticator"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi

    log::info "Installing Proton Authenticator"
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::ok "Proton Authenticator installed"
    else
        log::error "Failed to install Proton Authenticator"
    fi
    rm -f "$tmpfile"
    ui::return_or_exit
}

_protonauth::remove() {
    log::info "Removing Proton Authenticator"
    ui::flush_input
    if sudo apt-get remove -y proton-authenticator </dev/tty; then
        hash -r
        log::ok "Proton Authenticator removed"
    else
        log::error "Failed to remove Proton Authenticator"
    fi
    ui::return_or_exit
}
