# Nitrokey App2 task (Flatpak)

[[ -n "${_MOD_NITROKEY_LOADED:-}" ]] && return 0
_MOD_NITROKEY_LOADED=1

_NITROKEY_LABEL="Configure Nitrokey App2"
_NITROKEY_DESC="Install Nitrokey App2."
_NITROKEY_FLATPAK_ID="com.nitrokey.nitrokey-app2"

_nitrokey::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_NITROKEY_FLATPAK_ID"
}

nitrokey::check() {
    _nitrokey::is_installed
}

nitrokey::status() {
    _nitrokey::is_installed || printf 'not installed'
}

nitrokey::apply() {
    local choice

    while true; do
        local installed=false
        _nitrokey::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Hardware Keys > Nitrokey App2"
        log::break

        log::info "Nitrokey App2"

        if $installed; then
            local version
            version="$(flatpak info "$_NITROKEY_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Nitrokey App2: ${version}"
        else
            log::warn "Nitrokey App2 (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Nitrokey App2")
        else
            options+=("Install Nitrokey App2")
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
            "Install Nitrokey App2")
                log::break
                _nitrokey::install
                ;;
            "Remove Nitrokey App2")
                log::break
                _nitrokey::remove
                ;;
        esac
    done
}

_nitrokey::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Nitrokey App2"
    if flatpak install -y flathub "$_NITROKEY_FLATPAK_ID"; then
        log::ok "Nitrokey App2 installed"
    else
        log::error "Failed to install Nitrokey App2"
    fi
    ui::return_or_exit
}

_nitrokey::remove() {
    log::info "Removing Nitrokey App2"
    if flatpak remove -y "$_NITROKEY_FLATPAK_ID"; then
        log::ok "Nitrokey App2 removed"
    else
        log::error "Failed to remove Nitrokey App2"
    fi
    ui::return_or_exit
}
