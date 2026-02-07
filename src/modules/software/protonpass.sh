# Proton Pass task

[[ -n "${_MOD_PROTONPASS_LOADED:-}" ]] && return 0
_MOD_PROTONPASS_LOADED=1

_PROTONPASS_LABEL="Configure Proton Pass"
_PROTONPASS_DESC="Install Proton Pass password manager."
_PROTONPASS_DEB_URL="https://proton.me/download/PassDesktop/linux/x64/ProtonPass.deb"

_protonpass::is_installed() {
    dpkg -l proton-pass 2>/dev/null | grep -q '^ii'
}

protonpass::check() {
    _protonpass::is_installed
}

protonpass::status() {
    _protonpass::is_installed || printf 'not installed'
}

protonpass::apply() {
    local choice

    while true; do
        local installed=false
        _protonpass::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Password Managers > Proton Pass"
        log::break

        log::info "Proton Pass"

        if $installed; then
            local version
            version="$(dpkg -l proton-pass 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Proton Pass: ${version}"
        else
            log::warn "Proton Pass (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Proton Pass")
        else
            options+=("Install Proton Pass")
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
            "Install Proton Pass")
                log::break
                _protonpass::install
                ;;
            "Remove Proton Pass")
                log::break
                _protonpass::remove
                ;;
        esac
    done
}

_protonpass::install() {
    log::info "Downloading Proton Pass"
    ui::flush_input

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$_PROTONPASS_DEB_URL"; then
        log::error "Failed to download Proton Pass"
        rm -f "$tmpfile"
        return
    fi

    log::info "Installing Proton Pass"
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::ok "Proton Pass installed"
    else
        log::error "Failed to install Proton Pass"
    fi
    rm -f "$tmpfile"
}

_protonpass::remove() {
    log::info "Removing Proton Pass"
    ui::flush_input
    if sudo apt-get remove -y proton-pass </dev/tty; then
        hash -r
        log::ok "Proton Pass removed"
    else
        log::error "Failed to remove Proton Pass"
    fi
}
