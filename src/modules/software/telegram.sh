# Telegram Desktop task (Flatpak)

[[ -n "${_MOD_TELEGRAM_LOADED:-}" ]] && return 0
_MOD_TELEGRAM_LOADED=1

_TELEGRAM_LABEL="Configure Telegram"
_TELEGRAM_DESC="Install Telegram Desktop."
_TELEGRAM_FLATPAK_ID="org.telegram.desktop"

_telegram::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_TELEGRAM_FLATPAK_ID"
}

telegram::check() {
    _telegram::is_installed
}

telegram::status() {
    _telegram::is_installed || printf 'not installed'
}

telegram::apply() {
    local choice

    while true; do
        local installed=false
        _telegram::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Messaging > Telegram"
        log::break

        log::info "Telegram Desktop"

        if $installed; then
            local version
            version="$(flatpak info "$_TELEGRAM_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Telegram: ${version}"
        else
            log::warn "Telegram (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Telegram")
        else
            options+=("Install Telegram")
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
            "Install Telegram")
                log::break
                _telegram::install
                ;;
            "Remove Telegram")
                log::break
                _telegram::remove
                ;;
        esac
    done
}

_telegram::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Telegram"
    if flatpak install -y flathub "$_TELEGRAM_FLATPAK_ID"; then
        log::ok "Telegram installed"
    else
        log::error "Failed to install Telegram"
    fi
    ui::return_or_exit
}

_telegram::remove() {
    log::info "Removing Telegram"
    if flatpak remove -y "$_TELEGRAM_FLATPAK_ID"; then
        log::ok "Telegram removed"
    else
        log::error "Failed to remove Telegram"
    fi
    ui::return_or_exit
}
