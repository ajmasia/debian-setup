# KeePassXC task (Flatpak)

[[ -n "${_MOD_KEEPASSXC_LOADED:-}" ]] && return 0
_MOD_KEEPASSXC_LOADED=1

_KEEPASSXC_LABEL="Configure KeePassXC"
_KEEPASSXC_DESC="Install KeePassXC password manager."
_KEEPASSXC_FLATPAK_ID="org.keepassxc.KeePassXC"

_keepassxc::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_KEEPASSXC_FLATPAK_ID"
}

keepassxc::check() {
    _keepassxc::is_installed
}

keepassxc::status() {
    _keepassxc::is_installed || printf 'not installed'
}

keepassxc::apply() {
    local choice

    while true; do
        local installed=false
        _keepassxc::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Password Managers > KeePassXC"
        log::break

        log::info "KeePassXC"

        if $installed; then
            local version
            version="$(flatpak info "$_KEEPASSXC_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "KeePassXC: ${version}"
        else
            log::warn "KeePassXC (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove KeePassXC")
        else
            options+=("Install KeePassXC")
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
            "Install KeePassXC")
                log::break
                _keepassxc::install
                ;;
            "Remove KeePassXC")
                log::break
                _keepassxc::remove
                ;;
        esac
    done
}

_keepassxc::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing KeePassXC"
    if sudo flatpak install -y flathub "$_KEEPASSXC_FLATPAK_ID"; then
        log::ok "KeePassXC installed"
    else
        log::error "Failed to install KeePassXC"
    fi
    ui::return_or_exit
}

_keepassxc::remove() {
    log::info "Removing KeePassXC"
    if sudo flatpak remove -y "$_KEEPASSXC_FLATPAK_ID"; then
        log::ok "KeePassXC removed"
    else
        log::error "Failed to remove KeePassXC"
    fi
    ui::return_or_exit
}
