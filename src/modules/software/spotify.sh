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
                _spotify::install
                ;;
            "Fix desktop entry")
                log::break
                _spotify::fix_desktop
                ;;
            "Remove Spotify")
                log::break
                _spotify::remove
                ;;
        esac
    done
}

_spotify::install() {
    # Add GPG key
    if [[ ! -f "$_SPOTIFY_KEYRING" ]]; then
        log::info "Adding Spotify GPG key"
        ui::flush_input
        if ! curl -fsSL https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg \
            | sudo gpg --dearmor -o "$_SPOTIFY_KEYRING" </dev/tty; then
            log::error "Failed to add GPG key"
            return
        fi
    fi

    # Add repository
    local sources_file="/etc/apt/sources.list.d/spotify.list"
    if [[ ! -f "$sources_file" ]]; then
        log::info "Adding Spotify repository"
        printf 'deb [signed-by=%s] %s stable non-free\n' "$_SPOTIFY_KEYRING" "$_SPOTIFY_REPO_URL" \
            | sudo tee "$sources_file" >/dev/null
    fi

    log::info "Installing Spotify"
    ui::flush_input
    if sudo apt-get update -o Dir::Etc::sourcelist="$sources_file" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" -qq </dev/tty \
        && sudo apt-get install -y spotify-client </dev/tty; then
        hash -r
        log::ok "Spotify installed"
        _spotify::fix_desktop
    else
        log::error "Failed to install Spotify"
    fi
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
