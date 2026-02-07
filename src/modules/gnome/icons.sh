# Papirus Icons + Catppuccin folders task

[[ -n "${_MOD_GNOME_ICONS_LOADED:-}" ]] && return 0
_MOD_GNOME_ICONS_LOADED=1

_GNOME_ICONS_LABEL="Configure Icons"
_GNOME_ICONS_DESC="Install Papirus icons with Catppuccin folder colors."

_GNOME_ICONS_PAPIRUS_FOLDERS_REPO="https://github.com/catppuccin/papirus-folders.git"
_GNOME_ICONS_FOLDERS_SCRIPT="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders"

_gnome_icons::is_installed() {
    local current
    current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
    [[ "$current" == "'Papirus-Dark'" ]]
}

gnome_icons::check() {
    _gnome_icons::is_installed
}

gnome_icons::status() {
    _gnome_icons::is_installed || printf 'not installed'
}

gnome_icons::apply() {
    local choice

    while true; do
        local installed=false
        _gnome_icons::is_installed && installed=true

        ui::clear_content
        log::nav "GNOME > Appearance > Icons"
        log::break

        log::info "Papirus Icons + Catppuccin"

        if $installed; then
            log::ok "Icon theme: Papirus-Dark with Catppuccin"
        else
            local current
            current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
            log::warn "Icon theme: ${current} (not Papirus-Dark)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Revert Icons")
        else
            options+=("Install Papirus + Catppuccin")
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
            "Install Papirus + Catppuccin")
                log::break
                _gnome_icons::install
                ;;
            "Revert Icons")
                log::break
                _gnome_icons::revert
                ;;
        esac
    done
}

_gnome_icons::install() {
    # Install papirus base if missing
    if ! dpkg -l papirus-icon-theme 2>/dev/null | grep -q '^ii'; then
        log::info "Installing Papirus icon theme"
        ui::flush_input
        if ! sudo apt-get install -y papirus-icon-theme </dev/tty; then
            log::error "Failed to install Papirus"
            return
        fi
        hash -r
        log::ok "Papirus installed"
    else
        log::ok "Papirus already installed"
    fi

    # Choose accent
    local accent
    accent="$(gum::choose \
        --header "Select accent color for folder icons:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "lavender" "blue" "mauve" "pink" "rosewater" "flamingo" \
        "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire")"

    if [[ -z "$accent" ]]; then
        return
    fi

    # Clone Catppuccin folder assets
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Downloading Catppuccin folder icons"
    if ! git clone --depth 1 "$_GNOME_ICONS_PAPIRUS_FOLDERS_REPO" "$tmpdir/papirus-folders" 2>/dev/null; then
        log::error "Failed to clone repository"
        rm -rf "$tmpdir"
        return
    fi

    log::info "Applying Catppuccin folder colors"
    ui::flush_input
    sudo cp -r "$tmpdir/papirus-folders/src/"* /usr/share/icons/Papirus/ </dev/tty

    # Download and run papirus-folders script
    if ! curl -fsSL "$_GNOME_ICONS_FOLDERS_SCRIPT" -o "$tmpdir/papirus-folders-bin"; then
        log::error "Failed to download papirus-folders script"
        rm -rf "$tmpdir"
        return
    fi
    chmod +x "$tmpdir/papirus-folders-bin"

    if sudo "$tmpdir/papirus-folders-bin" -C "cat-mocha-${accent}" --theme Papirus-Dark </dev/tty; then
        log::ok "Folder colors applied: cat-mocha-${accent}"
    else
        log::warn "Failed to apply folder colors"
    fi

    rm -rf "$tmpdir"

    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" || true
    log::ok "Papirus-Dark icon theme applied"
}

_gnome_icons::revert() {
    log::info "Reverting icon theme to default"
    gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
    log::ok "Icon theme reverted"
}
