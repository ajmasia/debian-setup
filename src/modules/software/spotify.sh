# Spotify task (Flatpak)

[[ -n "${_MOD_SPOTIFY_LOADED:-}" ]] && return 0
_MOD_SPOTIFY_LOADED=1

_SPOTIFY_LABEL="Configure Spotify"
_SPOTIFY_DESC="Install Spotify music client."
_SPOTIFY_FLATPAK_ID="com.spotify.Client"

_spotify::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_SPOTIFY_FLATPAK_ID"
}

spotify::check() {
    _spotify::is_installed
}

spotify::status() {
    _spotify::is_installed || printf 'not installed'
}

spotify::apply() {
    local choice

    while true; do
        local installed=false
        _spotify::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Media > Spotify"
        log::break

        log::info "Spotify"

        if $installed; then
            local version
            version="$(flatpak info "$_SPOTIFY_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Spotify: ${version}"
        else
            log::warn "Spotify (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Spotify")
        else
            options+=("Install Spotify")
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
            "Install Spotify")
                log::break
                _spotify::install
                ;;
            "Remove Spotify")
                log::break
                _spotify::remove
                ;;
        esac
    done
}

_spotify::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Spotify"
    if sudo flatpak install -y flathub "$_SPOTIFY_FLATPAK_ID"; then
        log::ok "Spotify installed"
    else
        log::error "Failed to install Spotify"
    fi
    ui::return_or_exit
}

_spotify::remove() {
    log::info "Removing Spotify"
    if sudo flatpak remove -y "$_SPOTIFY_FLATPAK_ID"; then
        log::ok "Spotify removed"
    else
        log::error "Failed to remove Spotify"
    fi
    ui::return_or_exit
}
