# GNOME Terminal Catppuccin profile task

[[ -n "${_MOD_TERMPROFILE_LOADED:-}" ]] && return 0
_MOD_TERMPROFILE_LOADED=1

_TERMPROFILE_LABEL="Configure Terminal Profile"
_TERMPROFILE_DESC="Install Catppuccin color profiles for GNOME Terminal."

_TERMPROFILE_INSTALL_URL="https://raw.githubusercontent.com/catppuccin/gnome-terminal/v1.0.0/install.py"
_TERMPROFILE_UNINSTALL_URL="https://raw.githubusercontent.com/catppuccin/gnome-terminal/v1.0.0/uninstall.py"

_termprofile::is_installed() {
    local profiles
    profiles="$(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null || true)"
    [[ "$profiles" == *":"* ]] || return 1
    # Check if any profile has catppuccin in its name
    local profile_id
    while IFS= read -r profile_id; do
        local name
        name="$(dconf read "/org/gnome/terminal/legacy/profiles:/${profile_id}visible-name" 2>/dev/null || true)"
        if [[ "${name,,}" == *"catppuccin"* ]]; then
            return 0
        fi
    done < <(dconf list /org/gnome/terminal/legacy/profiles:/ 2>/dev/null | grep '^:')
    return 1
}

termprofile::check() {
    _termprofile::is_installed
}

termprofile::status() {
    _termprofile::is_installed || printf 'not installed'
}

termprofile::apply() {
    local choice

    while true; do
        local installed=false
        _termprofile::is_installed && installed=true

        ui::clear_content
        log::nav "GNOME > Appearance > Terminal Profile"
        log::break

        log::info "GNOME Terminal Color Profile"

        if $installed; then
            log::ok "Catppuccin profiles: installed"
        else
            log::warn "Catppuccin profiles (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Catppuccin Profiles")
        else
            options+=("Install Catppuccin Profiles")
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
            "Install Catppuccin Profiles")
                log::break
                _termprofile::install
                ;;
            "Remove Catppuccin Profiles")
                log::break
                _termprofile::remove
                ;;
        esac
    done
}

_termprofile::install() {
    if ! command -v python3 &>/dev/null; then
        log::error "python3 required. Install via System essentials"
        return
    fi

    log::info "Downloading GNOME Terminal Catppuccin installer"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! curl -fsSL "$_TERMPROFILE_INSTALL_URL" -o "$tmpdir/install.py"; then
        log::error "Failed to download install script"
        rm -rf "$tmpdir"
        return
    fi

    log::info "Installing color profiles"
    if python3 "$tmpdir/install.py"; then
        log::ok "Catppuccin profiles installed"
        log::break
        log::info "Set Catppuccin Mocha as default in GNOME Terminal > Preferences"
    else
        log::error "Failed to install profiles"
    fi

    rm -rf "$tmpdir"
}

_termprofile::remove() {
    log::info "Removing Catppuccin profiles"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if curl -fsSL "$_TERMPROFILE_UNINSTALL_URL" -o "$tmpdir/uninstall.py" 2>/dev/null; then
        if python3 "$tmpdir/uninstall.py"; then
            log::ok "Catppuccin profiles removed"
        else
            log::warn "Uninstall script failed"
            log::info "Remove profiles manually from GNOME Terminal > Preferences"
        fi
    else
        log::warn "Could not download uninstall script"
        log::info "Remove profiles manually from GNOME Terminal > Preferences"
    fi

    rm -rf "$tmpdir"
}
