# Balena Etcher task (AppImage from GitHub releases)

[[ -n "${_MOD_ETCHER_LOADED:-}" ]] && return 0
_MOD_ETCHER_LOADED=1

_ETCHER_LABEL="Configure Balena Etcher"
_ETCHER_DESC="Install Balena Etcher USB/SD card flasher."
_ETCHER_GH_API="https://api.github.com/repos/balena-io/etcher/releases/latest"
_ETCHER_ICON_URL="https://raw.githubusercontent.com/balena-io/etcher/master/assets/icon.png"
_ETCHER_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/balena-etcher"
_ETCHER_APPIMAGE="${_ETCHER_DIR}/balena-etcher.AppImage"
_ETCHER_DESKTOP="${XDG_DATA_HOME:-$HOME/.local/share}/applications/balena-etcher.desktop"
_ETCHER_ICON="${XDG_DATA_HOME:-$HOME/.local/share}/icons/balena-etcher.png"

_etcher::is_installed() {
    [[ -x "$_ETCHER_APPIMAGE" ]]
}

etcher::check() {
    _etcher::is_installed
}

etcher::status() {
    _etcher::is_installed || printf 'not installed'
}

etcher::apply() {
    local choice

    while true; do
        local installed=false
        _etcher::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > Balena Etcher"
        log::break

        log::info "Balena Etcher"

        if $installed; then
            log::ok "Balena Etcher: installed"
            log::ok "Path: ${_ETCHER_APPIMAGE}"
        else
            log::warn "Balena Etcher (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Balena Etcher")
        else
            options+=("Install Balena Etcher")
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
            "Install Balena Etcher")
                log::break
                _etcher::install
                ;;
            "Remove Balena Etcher")
                log::break
                _etcher::remove
                ;;
        esac
    done
}

_etcher::install() {
    log::info "Fetching latest release URL"

    local zip_url
    zip_url="$(curl -fsSL "$_ETCHER_GH_API" | grep -oP '"browser_download_url":\s*"\K[^"]*linux-x64[^"]*\.zip' || true)"

    if [[ -z "$zip_url" ]]; then
        log::error "Failed to find download URL"
        ui::return_or_exit
        return
    fi

    log::info "Downloading Balena Etcher"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! curl -fSL -o "${tmpdir}/etcher.zip" "$zip_url"; then
        log::error "Failed to download Balena Etcher"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi

    log::info "Extracting"
    if ! unzip -qo "${tmpdir}/etcher.zip" -d "$tmpdir"; then
        log::error "Failed to extract archive"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi

    # Find extracted directory
    local extracted_dir
    extracted_dir="$(find "$tmpdir" -maxdepth 1 -type d -name 'balenaEtcher*' | head -1)"

    if [[ -z "$extracted_dir" || ! -f "${extracted_dir}/balena-etcher" ]]; then
        log::error "Unexpected archive structure"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi

    # Install to XDG_DATA_HOME
    mkdir -p "$_ETCHER_DIR"
    rm -rf "${_ETCHER_DIR:?}/"*
    cp -a "${extracted_dir}/." "$_ETCHER_DIR/"
    mv "${_ETCHER_DIR}/balena-etcher" "$_ETCHER_APPIMAGE"
    chmod +x "$_ETCHER_APPIMAGE"

    # Download icon
    log::info "Downloading icon"
    mkdir -p "$(dirname "$_ETCHER_ICON")"
    curl -fsSL -o "$_ETCHER_ICON" "$_ETCHER_ICON_URL" || true

    # Create .desktop entry
    log::info "Creating desktop entry"
    mkdir -p "$(dirname "$_ETCHER_DESKTOP")"
    cat > "$_ETCHER_DESKTOP" <<EOF
[Desktop Entry]
Name=Balena Etcher
Comment=Flash OS images to SD cards and USB drives
Exec=${_ETCHER_APPIMAGE} --no-sandbox %U
Icon=${_ETCHER_ICON}
Terminal=false
Type=Application
Categories=Utility;
StartupWMClass=balena-etcher
EOF

    # Refresh desktop database
    update-desktop-database "$(dirname "$_ETCHER_DESKTOP")" 2>/dev/null || true

    rm -rf "$tmpdir"
    log::ok "Balena Etcher installed"
    ui::return_or_exit
}

_etcher::remove() {
    log::info "Removing Balena Etcher"

    rm -rf "$_ETCHER_DIR"
    rm -f "$_ETCHER_DESKTOP"
    rm -f "$_ETCHER_ICON"

    # Refresh desktop database
    update-desktop-database "$(dirname "$_ETCHER_DESKTOP")" 2>/dev/null || true

    log::ok "Balena Etcher removed"
    ui::return_or_exit
}
