# Google Chrome task

[[ -n "${_MOD_CHROME_LOADED:-}" ]] && return 0
_MOD_CHROME_LOADED=1

_CHROME_LABEL="Configure Google Chrome"
_CHROME_DESC="Install Google Chrome browser."
_CHROME_DEB_URL="https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"

_chrome::is_installed() {
    dpkg -l google-chrome-stable 2>/dev/null | grep -q '^ii'
}

chrome::check() {
    _chrome::is_installed
}

chrome::status() {
    _chrome::is_installed || printf 'not installed'
}

chrome::apply() {
    local choice

    while true; do
        local installed=false
        _chrome::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Browsers > Google Chrome"
        log::break

        log::info "Google Chrome"

        if $installed; then
            local version
            version="$(google-chrome-stable --version 2>/dev/null | sed 's/Google Chrome //' || true)"
            log::ok "Google Chrome: ${version}"
        else
            log::warn "Google Chrome (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Google Chrome")
        else
            options+=("Install Google Chrome")
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
            "Install Google Chrome")
                log::break
                _chrome::install
                ;;
            "Remove Google Chrome")
                log::break
                _chrome::remove
                ;;
        esac
    done
}

_chrome::install() {
    log::info "Downloading Google Chrome"
    ui::flush_input

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$_CHROME_DEB_URL"; then
        log::error "Failed to download Google Chrome"
        rm -f "$tmpfile"
        return
    fi

    log::info "Installing Google Chrome"
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::ok "Google Chrome installed"
    else
        log::error "Failed to install Google Chrome"
    fi
    rm -f "$tmpfile"
}

_chrome::remove() {
    log::info "Removing Google Chrome"
    ui::flush_input
    if sudo apt-get remove -y google-chrome-stable </dev/tty; then
        hash -r
        log::ok "Google Chrome removed"
    else
        log::error "Failed to remove Google Chrome"
    fi

    # Clean up repo and key that Chrome adds on install
    if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then
        sudo rm -f /etc/apt/sources.list.d/google-chrome.list
        log::ok "Removed Chrome APT repository"
    fi
    if [[ -f /usr/share/keyrings/google-chrome-keyring.gpg ]]; then
        sudo rm -f /usr/share/keyrings/google-chrome-keyring.gpg
        log::ok "Removed Chrome signing key"
    fi
}
