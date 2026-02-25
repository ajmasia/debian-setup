# Spotify task (APT repo + desktop fix for GNOME)

[[ -n "${_MOD_SPOTIFY_LOADED:-}" ]] && return 0
_MOD_SPOTIFY_LOADED=1

_SPOTIFY_LABEL="Configure Spotify"
_SPOTIFY_DESC="Install Spotify music client."
_SPOTIFY_REPO_URL="http://repository.spotify.com"
_SPOTIFY_KEYRING="/usr/share/keyrings/spotify-archive-keyring.gpg"
_SPOTIFY_DESKTOP_SRC="/usr/share/applications/spotify.desktop"
_SPOTIFY_DESKTOP_DEST="${HOME}/.local/share/applications/spotify.desktop"

_spotify::is_installed() {
    dpkg -l spotify-client 2>/dev/null | grep -q '^ii'
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
            version="$(dpkg -l spotify-client 2>/dev/null | awk '/^ii/{print $3}')"
            log::ok "Spotify: ${version}"

            if [[ -f "$_SPOTIFY_DESKTOP_DEST" ]]; then
                log::ok "Desktop entry: GNOME native decorations"
            else
                log::warn "Desktop entry: not patched"
            fi
        else
            log::warn "Spotify (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            if [[ ! -f "$_SPOTIFY_DESKTOP_DEST" ]]; then
                options+=("Fix desktop entry")
            fi
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
                _spotify::install || true
                ;;
            "Fix desktop entry")
                log::break
                _spotify::fix_desktop || true
                ;;
            "Remove Spotify")
                log::break
                _spotify::remove || true
                ;;
        esac
    done
}

_spotify::install() {
    log::info "Adding Spotify repository"
    ui::flush_input

    # Download GPG key and dearmor (same pattern as Docker module)
    if [[ ! -f "$_SPOTIFY_KEYRING" ]]; then
        if ! curl -fsSL https://download.spotify.com/debian/pubkey_5384CE82BA52C83A.gpg \
            | sudo gpg --dearmor --yes -o "$_SPOTIFY_KEYRING"; then
            log::error "Failed to download Spotify GPG key"
            ui::return_or_exit
            return
        fi
        sudo chmod 644 "$_SPOTIFY_KEYRING"
    fi

    # Add repository
    local sources_file="/etc/apt/sources.list.d/spotify.list"
    if [[ ! -f "$sources_file" ]]; then
        printf 'deb [signed-by=%s] %s stable non-free\n' "$_SPOTIFY_KEYRING" "$_SPOTIFY_REPO_URL" \
            | sudo tee "$sources_file" >/dev/null
    fi

    log::info "Installing Spotify"
    if sudo apt-get update -o Dir::Etc::sourcelist="$sources_file" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" -qq </dev/tty \
        && sudo apt-get install -y spotify-client </dev/tty; then
        hash -r
        log::ok "Spotify installed"
        _spotify::fix_desktop
    else
        log::error "Failed to install Spotify"
    fi
    ui::return_or_exit
}

_spotify::fix_desktop() {
    if [[ ! -f "$_SPOTIFY_DESKTOP_SRC" ]]; then
        log::warn "Desktop entry not found"
        return
    fi

    sed 's|^Exec=spotify|Exec=spotify --ozone-platform=x11 --gtk-version=4|' \
        "$_SPOTIFY_DESKTOP_SRC" > "$_SPOTIFY_DESKTOP_DEST"
    log::ok "Desktop entry patched for GNOME native decorations"
}

_spotify::remove() {
    log::info "Removing Spotify"
    ui::flush_input
    if sudo apt-get remove -y spotify-client </dev/tty; then
        hash -r
        rm -f "$_SPOTIFY_DESKTOP_DEST"
        log::ok "Spotify removed"
    else
        log::error "Failed to remove Spotify"
    fi
}
