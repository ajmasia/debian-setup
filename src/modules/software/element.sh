# Element Desktop task (APT repo)

[[ -n "${_MOD_ELEMENT_LOADED:-}" ]] && return 0
_MOD_ELEMENT_LOADED=1

_ELEMENT_LABEL="Configure Element"
_ELEMENT_DESC="Install Element Desktop."

_ELEMENT_GPG_URL="https://packages.element.io/debian/element-io-archive-keyring.gpg"
_ELEMENT_GPG_KEY="/usr/share/keyrings/element-io-archive-keyring.gpg"
_ELEMENT_SOURCES="/etc/apt/sources.list.d/element-io.list"

_element::is_installed() {
    dpkg -l element-desktop 2>/dev/null | grep -q '^ii'
}

element::check() {
    _element::is_installed
}

element::status() {
    _element::is_installed || printf 'not installed'
}

element::apply() {
    local choice

    while true; do
        local installed=false
        _element::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Messaging > Element"
        log::break

        log::info "Element Desktop"

        if $installed; then
            local version
            version="$(dpkg -l element-desktop 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Element: ${version}"
        else
            log::warn "Element (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Element")
        else
            options+=("Install Element")
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
            "Install Element")
                log::break
                _element::install
                ;;
            "Remove Element")
                log::break
                _element::remove
                ;;
        esac
    done
}

_element::install() {
    log::info "Adding Element repository"
    ui::flush_input

    if ! sudo curl -fsSLo "$_ELEMENT_GPG_KEY" "$_ELEMENT_GPG_URL" </dev/tty; then
        log::error "Failed to download Element GPG key"
        return
    fi
    sudo chmod 644 "$_ELEMENT_GPG_KEY"

    printf 'deb [signed-by=%s] https://packages.element.io/debian/ default main\n' \
        "$_ELEMENT_GPG_KEY" | sudo tee "$_ELEMENT_SOURCES" > /dev/null
    log::ok "Repository added"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing Element"
    if sudo apt-get install -y element-desktop </dev/tty; then
        hash -r
        log::ok "Element installed"
    else
        log::error "Failed to install Element"
    fi
}

_element::remove() {
    log::info "Removing Element"
    ui::flush_input
    if sudo apt-get remove -y element-desktop </dev/tty; then
        hash -r
        log::ok "Element removed"
    else
        log::error "Failed to remove Element"
        return
    fi

    if [[ -f "$_ELEMENT_SOURCES" ]]; then
        sudo rm -f "$_ELEMENT_SOURCES"
        log::ok "Element repository removed"
    fi
    if [[ -f "$_ELEMENT_GPG_KEY" ]]; then
        sudo rm -f "$_ELEMENT_GPG_KEY"
        log::ok "Element GPG key removed"
    fi
}
