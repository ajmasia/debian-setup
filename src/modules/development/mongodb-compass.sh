# MongoDB Compass task (Flatpak)

[[ -n "${_MOD_COMPASS_LOADED:-}" ]] && return 0
_MOD_COMPASS_LOADED=1

_COMPASS_LABEL="Configure MongoDB Compass"
_COMPASS_DESC="Install MongoDB Compass."
_COMPASS_FLATPAK_ID="com.mongodb.Compass"

_compass::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_COMPASS_FLATPAK_ID"
}

compass::check() {
    _compass::is_installed
}

compass::status() {
    _compass::is_installed || printf 'not installed'
}

compass::apply() {
    local choice

    while true; do
        local installed=false
        _compass::is_installed && installed=true

        ui::clear_content
        log::nav "Development > Tools > MongoDB Compass"
        log::break

        log::info "MongoDB Compass"

        if $installed; then
            local version
            version="$(flatpak info "$_COMPASS_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "MongoDB Compass: ${version}"
        else
            log::warn "MongoDB Compass (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove MongoDB Compass")
        else
            options+=("Install MongoDB Compass")
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
            "Install MongoDB Compass")
                log::break
                _compass::install
                ;;
            "Remove MongoDB Compass")
                log::break
                _compass::remove
                ;;
        esac
    done
}

_compass::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        return
    fi

    log::info "Installing MongoDB Compass"
    if flatpak install -y flathub "$_COMPASS_FLATPAK_ID"; then
        log::ok "MongoDB Compass installed"
    else
        log::error "Failed to install MongoDB Compass"
    fi
}

_compass::remove() {
    log::info "Removing MongoDB Compass"
    if flatpak remove -y "$_COMPASS_FLATPAK_ID"; then
        log::ok "MongoDB Compass removed"
    else
        log::error "Failed to remove MongoDB Compass"
    fi
}
