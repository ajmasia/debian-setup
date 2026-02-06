# Flatpak package manager task

[[ -n "${_MOD_FLATPAK_LOADED:-}" ]] && return 0
_MOD_FLATPAK_LOADED=1

_FLATPAK_LABEL="Configure Flatpak"
_FLATPAK_DESC="Install or remove Flatpak universal package manager
and the Flathub repository."

_FLATPAK_FLATHUB_URL="https://dl.flathub.org/repo/flathub.flatpakrepo"

_flatpak::is_installed() {
    command -v flatpak &>/dev/null
}

_flatpak::has_flathub() {
    _flatpak::is_installed && flatpak remotes --columns=name 2>/dev/null | grep -q "^flathub$"
}

_flatpak::session_ready() {
    [[ "${XDG_DATA_DIRS:-}" == */flatpak* ]]
}

flatpak::check() {
    _flatpak::is_installed && _flatpak::has_flathub && _flatpak::session_ready
}

flatpak::status() {
    local issues=()
    _flatpak::is_installed || issues+=("not installed")
    _flatpak::is_installed && ! _flatpak::has_flathub && issues+=("missing Flathub")
    _flatpak::is_installed && ! _flatpak::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

flatpak::apply() {
    local choice

    while true; do
        local installed=false has_flathub=false
        _flatpak::is_installed && installed=true
        _flatpak::has_flathub && has_flathub=true

        ui::clear_content
        log::nav "Package managers > Configure Flatpak"
        log::break

        log::info "Current Flatpak configuration"

        if $installed; then
            local version
            version="$(flatpak --version 2>/dev/null || true)"
            log::ok "Flatpak: installed (${version})"
        else
            log::warn "Flatpak: not installed"
        fi

        if $installed; then
            if $has_flathub; then
                log::ok "Flathub: enabled"
            else
                log::warn "Flathub: not configured"
            fi

            # Detect if restart is needed (flatpak paths not in session)
            if [[ "$XDG_DATA_DIRS" != */flatpak* ]]; then
                log::warn "Restart needed to complete Flatpak integration"
            fi
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            if ! $has_flathub; then
                options+=("Add Flathub repository")
            else
                options+=("Remove Flathub repository")
            fi
            options+=("Remove Flatpak")
        else
            options+=("Install Flatpak")
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
            "Install Flatpak")
                log::break
                log::info "Installing Flatpak"
                ui::flush_input
                if sudo apt install -y flatpak </dev/tty; then
                    hash -r
                    log::ok "Flatpak installed"
                    log::break
                    log::info "Adding Flathub repository"
                    flatpak remote-add --if-not-exists flathub "$_FLATPAK_FLATHUB_URL"
                    log::ok "Flathub repository added"
                else
                    log::error "Failed to install Flatpak"
                fi
                ;;
            "Add Flathub repository")
                log::break
                log::info "Adding Flathub repository"
                flatpak remote-add --if-not-exists flathub "$_FLATPAK_FLATHUB_URL"
                log::ok "Flathub repository added"
                ;;
            "Remove Flathub repository")
                log::break
                log::info "Removing Flathub repository"
                if flatpak remote-delete flathub; then
                    log::ok "Flathub repository removed"
                else
                    log::error "Failed to remove Flathub"
                fi
                ;;
            "Remove Flatpak")
                log::break
                log::info "Removing Flatpak"
                ui::flush_input
                if sudo apt remove -y flatpak </dev/tty; then
                    hash -r
                    log::ok "Flatpak removed"
                else
                    log::error "Failed to remove Flatpak"
                fi
                ;;
        esac
    done
}
