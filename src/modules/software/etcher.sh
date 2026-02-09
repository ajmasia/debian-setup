# Balena Etcher task (deb from GitHub releases)

[[ -n "${_MOD_ETCHER_LOADED:-}" ]] && return 0
_MOD_ETCHER_LOADED=1

_ETCHER_LABEL="Configure Balena Etcher"
_ETCHER_DESC="Install Balena Etcher USB/SD card flasher."
_ETCHER_PKG="balena-etcher"
_ETCHER_DEB_URL="https://github.com/balena-io/etcher/releases/latest/download/balena-etcher_amd64.deb"

_etcher::is_installed() {
    dpkg -l "$_ETCHER_PKG" 2>/dev/null | grep -q '^ii'
}

etcher::check() {
    _etcher::is_installed
}

etcher::status() {
    _etcher::is_installed || printf 'not installed'
}

etcher::apply() {
    local choice

    while true; do
        local installed=false
        _etcher::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > Balena Etcher"
        log::break

        log::info "Balena Etcher"

        if $installed; then
            local version
            version="$(dpkg -l "$_ETCHER_PKG" 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Balena Etcher: ${version}"
        else
            log::warn "Balena Etcher (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Balena Etcher")
        else
            options+=("Install Balena Etcher")
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
            "Install Balena Etcher")
                log::break
                _etcher::install
                ;;
            "Remove Balena Etcher")
                log::break
                _etcher::remove
                ;;
        esac
    done
}

_etcher::install() {
    log::info "Downloading Balena Etcher"
    ui::flush_input

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! curl -fSL -o "$tmpfile" "$_ETCHER_DEB_URL"; then
        log::error "Failed to download Balena Etcher"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi

    chmod 644 "$tmpfile"

    log::info "Installing Balena Etcher"
    if sudo dpkg -i "$tmpfile" </dev/tty; then
        hash -r
        log::ok "Balena Etcher installed"
    else
        log::warn "Resolving dependencies"
        if sudo apt-get install -f -y </dev/tty; then
            hash -r
            log::ok "Balena Etcher installed"
        else
            log::error "Failed to install Balena Etcher"
        fi
    fi
    rm -f "$tmpfile"
    ui::return_or_exit
}

_etcher::remove() {
    log::info "Removing Balena Etcher"
    ui::flush_input
    if sudo apt-get remove -y "$_ETCHER_PKG" </dev/tty; then
        hash -r
        log::ok "Balena Etcher removed"
    else
        log::error "Failed to remove Balena Etcher"
    fi
    ui::return_or_exit
}
