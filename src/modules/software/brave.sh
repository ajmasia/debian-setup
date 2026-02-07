# Brave browser task

[[ -n "${_MOD_BRAVE_LOADED:-}" ]] && return 0
_MOD_BRAVE_LOADED=1

_BRAVE_LABEL="Configure Brave"
_BRAVE_DESC="Install Brave browser."

_BRAVE_GPG_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
_BRAVE_GPG_KEY="/usr/share/keyrings/brave-browser-archive-keyring.gpg"
_BRAVE_SOURCES_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser.sources"
_BRAVE_SOURCES="/etc/apt/sources.list.d/brave-browser-release.sources"

_brave::is_installed() {
    dpkg -l brave-browser 2>/dev/null | grep -q '^ii'
}

brave::check() {
    _brave::is_installed
}

brave::status() {
    _brave::is_installed || printf 'not installed'
}

brave::apply() {
    local choice

    while true; do
        local installed=false
        _brave::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Browsers > Brave"
        log::break

        log::info "Brave Browser"

        if $installed; then
            local version
            version="$(brave-browser --version 2>/dev/null || true)"
            log::ok "Brave: ${version}"
        else
            log::warn "Brave (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Brave")
        else
            options+=("Install Brave")
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
            "Install Brave")
                log::break
                _brave::install
                ;;
            "Remove Brave")
                log::break
                _brave::remove
                ;;
        esac
    done
}

_brave::install() {
    log::info "Adding Brave repository"
    ui::flush_input

    if ! sudo curl -fsSLo "$_BRAVE_GPG_KEY" "$_BRAVE_GPG_URL" </dev/tty; then
        log::error "Failed to download Brave GPG key"
        return
    fi
    sudo chmod 644 "$_BRAVE_GPG_KEY"

    if ! sudo curl -fsSLo "$_BRAVE_SOURCES" "$_BRAVE_SOURCES_URL" </dev/tty; then
        log::error "Failed to download Brave sources"
        return
    fi
    log::ok "Repository added"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing Brave"
    if sudo apt-get install -y brave-browser </dev/tty; then
        hash -r
        log::ok "Brave installed"
    else
        log::error "Failed to install Brave"
    fi
}

_brave::remove() {
    log::info "Removing Brave"
    ui::flush_input
    if sudo apt-get remove -y brave-browser </dev/tty; then
        hash -r
        log::ok "Brave removed"
    else
        log::error "Failed to remove Brave"
        return
    fi

    if [[ -f "$_BRAVE_SOURCES" ]]; then
        sudo rm -f "$_BRAVE_SOURCES"
        log::ok "Brave repository removed"
    fi
    if [[ -f "$_BRAVE_GPG_KEY" ]]; then
        sudo rm -f "$_BRAVE_GPG_KEY"
        log::ok "Brave GPG key removed"
    fi
}
