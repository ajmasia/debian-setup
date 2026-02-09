# Yubico Authenticator task (Flatpak)

[[ -n "${_MOD_YUBICOAUTH_LOADED:-}" ]] && return 0
_MOD_YUBICOAUTH_LOADED=1

_YUBICOAUTH_LABEL="Configure Yubico Authenticator"
_YUBICOAUTH_DESC="Install Yubico Authenticator."
_YUBICOAUTH_FLATPAK_ID="com.yubico.yubioath"

_yubicoauth::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_YUBICOAUTH_FLATPAK_ID"
}

yubicoauth::check() {
    _yubicoauth::is_installed
}

yubicoauth::status() {
    _yubicoauth::is_installed || printf 'not installed'
}

yubicoauth::apply() {
    local choice

    while true; do
        local installed=false
        _yubicoauth::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Authenticators > Yubico Authenticator"
        log::break

        log::info "Yubico Authenticator"

        if $installed; then
            local version
            version="$(flatpak info "$_YUBICOAUTH_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Yubico Authenticator: ${version}"
        else
            log::warn "Yubico Authenticator (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Yubico Authenticator")
        else
            options+=("Install Yubico Authenticator")
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
            "Install Yubico Authenticator")
                log::break
                _yubicoauth::install
                ;;
            "Remove Yubico Authenticator")
                log::break
                _yubicoauth::remove
                ;;
        esac
    done
}

_yubicoauth::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Yubico Authenticator"
    if flatpak install -y flathub "$_YUBICOAUTH_FLATPAK_ID"; then
        log::ok "Yubico Authenticator installed"
    else
        log::error "Failed to install Yubico Authenticator"
    fi
    ui::return_or_exit
}

_yubicoauth::remove() {
    log::info "Removing Yubico Authenticator"
    if flatpak remove -y "$_YUBICOAUTH_FLATPAK_ID"; then
        log::ok "Yubico Authenticator removed"
    else
        log::error "Failed to remove Yubico Authenticator"
    fi
    ui::return_or_exit
}
