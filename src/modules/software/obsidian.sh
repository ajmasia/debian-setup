# Obsidian task

[[ -n "${_MOD_OBSIDIAN_LOADED:-}" ]] && return 0
_MOD_OBSIDIAN_LOADED=1

_OBSIDIAN_LABEL="Configure Obsidian"
_OBSIDIAN_DESC="Install Obsidian note-taking app."
_OBSIDIAN_GH_API="https://api.github.com/repos/obsidianmd/obsidian-releases/releases/latest"
_OBSIDIAN_PKG="obsidian"

_obsidian::is_installed() {
    dpkg -l "$_OBSIDIAN_PKG" 2>/dev/null | grep -q '^ii'
}

obsidian::check() {
    _obsidian::is_installed
}

obsidian::status() {
    _obsidian::is_installed || printf 'not installed'
}

obsidian::apply() {
    local choice

    while true; do
        local installed=false
        _obsidian::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > Obsidian"
        log::break

        log::info "Obsidian"

        if $installed; then
            local version
            version="$(dpkg -l "$_OBSIDIAN_PKG" 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Obsidian: ${version}"
        else
            log::warn "Obsidian (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Obsidian" "Remove Obsidian")
        else
            options+=("Install Obsidian")
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
            "Install Obsidian"|"Update Obsidian")
                log::break
                _obsidian::install
                ;;
            "Remove Obsidian")
                log::break
                _obsidian::remove
                ;;
        esac
    done
}

_obsidian::install() {
    log::info "Fetching latest Obsidian version"

    local json version
    json="$(curl -fsSL "$_OBSIDIAN_GH_API" 2>/dev/null || true)"

    if [[ -z "$json" ]]; then
        log::error "Failed to fetch Obsidian release info"
        ui::return_or_exit
        return
    fi

    version="$(printf '%s' "$json" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"

    if [[ -z "$version" ]]; then
        log::error "Failed to parse Obsidian version"
        ui::return_or_exit
        return
    fi

    log::ok "Latest version: ${version}"

    local url="https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb"

    log::info "Downloading Obsidian ${version}"

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$url"; then
        log::error "Failed to download Obsidian"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi

    log::info "Installing Obsidian ${version}"
    ui::flush_input
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::ok "Obsidian ${version} installed"
    else
        log::error "Failed to install Obsidian"
    fi
    rm -f "$tmpfile"
    ui::return_or_exit
}

_obsidian::remove() {
    log::info "Removing Obsidian"
    ui::flush_input
    if sudo apt-get remove -y "$_OBSIDIAN_PKG" </dev/tty; then
        hash -r
        log::ok "Obsidian removed"
    else
        log::error "Failed to remove Obsidian"
    fi
    ui::return_or_exit
}
