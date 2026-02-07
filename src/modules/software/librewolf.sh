# LibreWolf browser task

[[ -n "${_MOD_LIBREWOLF_LOADED:-}" ]] && return 0
_MOD_LIBREWOLF_LOADED=1

_LIBREWOLF_LABEL="Configure LibreWolf"
_LIBREWOLF_DESC="Install LibreWolf browser via extrepo."

_librewolf::is_installed() {
    dpkg -l librewolf 2>/dev/null | grep -q '^ii'
}

_librewolf::extrepo_installed() {
    dpkg -l extrepo 2>/dev/null | grep -q '^ii'
}

_librewolf::repo_enabled() {
    [[ -f /etc/apt/sources.list.d/extrepo_librewolf.sources ]]
}

librewolf::check() {
    _librewolf::is_installed
}

librewolf::status() {
    _librewolf::is_installed || printf 'not installed'
}

librewolf::apply() {
    local choice

    while true; do
        local installed=false
        _librewolf::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Browsers > LibreWolf"
        log::break

        log::info "LibreWolf"

        if $installed; then
            local version
            version="$(librewolf --version 2>/dev/null || true)"
            log::ok "LibreWolf: ${version}"
        else
            log::warn "LibreWolf (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove LibreWolf")
        else
            options+=("Install LibreWolf")
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
            "Install LibreWolf")
                log::break
                _librewolf::install
                ;;
            "Remove LibreWolf")
                log::break
                _librewolf::remove
                ;;
        esac
    done
}

_librewolf::install() {
    ui::flush_input

    if ! _librewolf::extrepo_installed; then
        log::info "Installing extrepo"
        if ! sudo apt-get install -y extrepo </dev/tty; then
            log::error "Failed to install extrepo"
            return
        fi
        hash -r
        log::ok "extrepo installed"
    fi

    log::info "Enabling LibreWolf repository"
    if ! sudo extrepo enable librewolf </dev/tty; then
        log::error "Failed to enable LibreWolf repository"
        return
    fi
    log::ok "Repository enabled"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing LibreWolf"
    if sudo apt-get install -y librewolf </dev/tty; then
        hash -r
        log::ok "LibreWolf installed"
    else
        log::error "Failed to install LibreWolf"
    fi
}

_librewolf::remove() {
    log::info "Removing LibreWolf"
    ui::flush_input
    if sudo apt-get remove -y librewolf </dev/tty; then
        hash -r
        log::ok "LibreWolf removed"
    else
        log::error "Failed to remove LibreWolf"
        return
    fi

    if _librewolf::repo_enabled; then
        log::info "Disabling LibreWolf repository"
        sudo extrepo disable librewolf 2>/dev/null || true
        log::ok "Repository disabled"
    fi
}
