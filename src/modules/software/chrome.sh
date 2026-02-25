# Google Chrome task (APT repo)

[[ -n "${_MOD_CHROME_LOADED:-}" ]] && return 0
_MOD_CHROME_LOADED=1

_CHROME_LABEL="Configure Google Chrome"
_CHROME_DESC="Install Google Chrome browser."
_CHROME_REPO_URL="https://dl.google.com/linux/chrome/deb/"
_CHROME_KEYRING="/usr/share/keyrings/google-chrome-keyring.gpg"

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
            version="$(dpkg -l google-chrome-stable 2>/dev/null | awk '/^ii/{print $3}')"
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
                _chrome::install || true
                ;;
            "Remove Google Chrome")
                log::break
                _chrome::remove || true
                ;;
        esac
    done
}

_chrome::install() {
    log::info "Adding Google Chrome repository"
    ui::flush_input

    # Download GPG key and dearmor
    if [[ ! -f "$_CHROME_KEYRING" ]]; then
        if ! curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
            | sudo gpg --dearmor --yes -o "$_CHROME_KEYRING"; then
            log::error "Failed to download Google Chrome GPG key"
            ui::return_or_exit
            return
        fi
        sudo chmod 644 "$_CHROME_KEYRING"
    fi

    # Add repository
    local sources_file="/etc/apt/sources.list.d/google-chrome.list"
    if [[ ! -f "$sources_file" ]]; then
        printf 'deb [arch=amd64 signed-by=%s] %s stable main\n' "$_CHROME_KEYRING" "$_CHROME_REPO_URL" \
            | sudo tee "$sources_file" >/dev/null
    fi

    log::info "Installing Google Chrome"
    if sudo apt-get update -o Dir::Etc::sourcelist="$sources_file" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" -qq </dev/tty \
        && sudo apt-get install -y google-chrome-stable </dev/tty; then
        hash -r
        log::ok "Google Chrome installed"
    else
        log::error "Failed to install Google Chrome"
    fi
    ui::return_or_exit
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

    # Clean up repo and key
    if [[ -f /etc/apt/sources.list.d/google-chrome.list ]]; then
        sudo rm -f /etc/apt/sources.list.d/google-chrome.list
        log::ok "Removed Chrome APT repository"
    fi
    if [[ -f "$_CHROME_KEYRING" ]]; then
        sudo rm -f "$_CHROME_KEYRING"
        log::ok "Removed Chrome signing key"
    fi
}
