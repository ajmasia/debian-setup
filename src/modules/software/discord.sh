# Discord task (Flatpak)

[[ -n "${_MOD_DISCORD_LOADED:-}" ]] && return 0
_MOD_DISCORD_LOADED=1

_DISCORD_LABEL="Configure Discord"
_DISCORD_DESC="Install Discord."
_DISCORD_FLATPAK_ID="com.discordapp.Discord"

_discord::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_DISCORD_FLATPAK_ID"
}

discord::check() {
    _discord::is_installed
}

discord::status() {
    _discord::is_installed || printf 'not installed'
}

discord::apply() {
    local choice

    while true; do
        local installed=false
        _discord::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Messaging > Discord"
        log::break

        log::info "Discord"

        if $installed; then
            local version
            version="$(flatpak info "$_DISCORD_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Discord: ${version}"
        else
            log::warn "Discord (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Discord")
        else
            options+=("Install Discord")
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
            "Install Discord")
                log::break
                _discord::install
                ;;
            "Remove Discord")
                log::break
                _discord::remove
                ;;
        esac
    done
}

_discord::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Discord"
    if flatpak install -y flathub "$_DISCORD_FLATPAK_ID"; then
        log::ok "Discord installed"
    else
        log::error "Failed to install Discord"
    fi
    ui::return_or_exit
}

_discord::remove() {
    log::info "Removing Discord"
    if flatpak remove -y "$_DISCORD_FLATPAK_ID"; then
        log::ok "Discord removed"
    else
        log::error "Failed to remove Discord"
    fi
    ui::return_or_exit
}
