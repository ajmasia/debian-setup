# Kitty terminal emulator task

[[ -n "${_MOD_KITTY_LOADED:-}" ]] && return 0
_MOD_KITTY_LOADED=1

_KITTY_LABEL="Configure Kitty"
_KITTY_DESC="Install Kitty terminal emulator."
_KITTY_INSTALL_DIR="$HOME/.local/kitty.app"
_KITTY_INSTALLER_URL="https://sw.kovidgoyal.net/kitty/installer.sh"

_kitty::is_installed() {
    [[ -d "$_KITTY_INSTALL_DIR" ]]
}

_kitty::session_ready() {
    command -v kitty &>/dev/null
}

kitty::check() {
    _kitty::is_installed && _kitty::session_ready
}

kitty::status() {
    local issues=()
    _kitty::is_installed || issues+=("not installed")
    _kitty::is_installed && ! _kitty::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

kitty::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _kitty::is_installed && installed=true
        _kitty::session_ready && session_ready=true

        ui::clear_content
        log::nav "Software > Terminals > Kitty"
        log::break

        log::info "Kitty"

        if $installed; then
            if $session_ready; then
                local version
                version="$(kitty --version 2>/dev/null || true)"
                log::ok "Kitty: ${version}"
            else
                log::ok "Kitty: installed"
                log::warn "Restart needed to activate kitty in current session"
            fi
        else
            log::warn "Kitty (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Kitty" "Remove Kitty")
        else
            options+=("Install Kitty")
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
            "Install Kitty"|"Update Kitty")
                log::break
                _kitty::install
                ;;
            "Remove Kitty")
                log::break
                _kitty::remove
                ;;
        esac
    done
}

_kitty::install() {
    log::info "Downloading and installing Kitty"

    if ! curl -L "$_KITTY_INSTALLER_URL" | sh /dev/stdin; then
        log::error "Failed to install Kitty"
        ui::return_or_exit
        return
    fi

    log::ok "Kitty installed"

    # Symlinks to ~/.local/bin
    mkdir -p "$HOME/.local/bin"
    ln -sf "$_KITTY_INSTALL_DIR/bin/kitty" "$HOME/.local/bin/"
    ln -sf "$_KITTY_INSTALL_DIR/bin/kitten" "$HOME/.local/bin/"
    log::ok "Symlinks created in ~/.local/bin"

    # Desktop integration for GNOME
    local home_real
    home_real="$(realpath "$HOME")"

    mkdir -p "$HOME/.local/share/applications"

    if [[ -f "$_KITTY_INSTALL_DIR/share/applications/kitty.desktop" ]]; then
        cp "$_KITTY_INSTALL_DIR/share/applications/kitty.desktop" \
            "$HOME/.local/share/applications/"
        sed -i "s|Icon=kitty|Icon=${home_real}/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
            "$HOME/.local/share/applications/kitty.desktop"
        sed -i "s|Exec=kitty|Exec=${home_real}/.local/kitty.app/bin/kitty|g" \
            "$HOME/.local/share/applications/kitty.desktop"
    fi

    if [[ -f "$_KITTY_INSTALL_DIR/share/applications/kitty-open.desktop" ]]; then
        cp "$_KITTY_INSTALL_DIR/share/applications/kitty-open.desktop" \
            "$HOME/.local/share/applications/"
        sed -i "s|Icon=kitty|Icon=${home_real}/.local/kitty.app/share/icons/hicolor/256x256/apps/kitty.png|g" \
            "$HOME/.local/share/applications/kitty-open.desktop"
        sed -i "s|Exec=kitty|Exec=${home_real}/.local/kitty.app/bin/kitty|g" \
            "$HOME/.local/share/applications/kitty-open.desktop"
    fi

    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    log::ok "Desktop integration configured"
    hash -r

    # PATH warning
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi

    ui::return_or_exit
}

_kitty::remove() {
    log::info "Removing Kitty"

    rm -rf "$_KITTY_INSTALL_DIR"
    rm -f "$HOME/.local/bin/kitty"
    rm -f "$HOME/.local/bin/kitten"
    rm -f "$HOME/.local/share/applications/kitty.desktop"
    rm -f "$HOME/.local/share/applications/kitty-open.desktop"
    update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
    hash -r

    log::ok "Kitty removed"
    ui::return_or_exit
}
