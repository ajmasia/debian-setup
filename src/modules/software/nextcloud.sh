# Nextcloud Desktop task (Flatpak + Nautilus plugin)

[[ -n "${_MOD_NEXTCLOUD_LOADED:-}" ]] && return 0
_MOD_NEXTCLOUD_LOADED=1

_NEXTCLOUD_LABEL="Configure Nextcloud"
_NEXTCLOUD_DESC="Install Nextcloud Desktop client and Nautilus integration."

_NEXTCLOUD_FLATPAK_ID="com.nextcloud.desktopclient.nextcloud"
_NEXTCLOUD_NAUTILUS_PKG="nautilus-nextcloud"

_nextcloud::app_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_NEXTCLOUD_FLATPAK_ID"
}

_nextcloud::nautilus_installed() {
    dpkg -l "$_NEXTCLOUD_NAUTILUS_PKG" 2>/dev/null | grep -q '^ii'
}

nextcloud::check() {
    _nextcloud::app_installed && _nextcloud::nautilus_installed
}

nextcloud::status() {
    local missing=()
    _nextcloud::app_installed || missing+=("client")
    _nextcloud::nautilus_installed || missing+=("nautilus plugin")
    if [[ ${#missing[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s not installed' "${missing[*]}"
    fi
}

nextcloud::apply() {
    local choice

    while true; do
        local app=false nautilus=false
        _nextcloud::app_installed && app=true
        _nextcloud::nautilus_installed && nautilus=true

        ui::clear_content
        log::nav "Software > Productivity > Nextcloud"
        log::break

        log::info "Nextcloud Desktop"

        if $app; then
            local version
            version="$(flatpak info "$_NEXTCLOUD_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Nextcloud Desktop: ${version}"
        else
            log::warn "Nextcloud Desktop (not installed)"
        fi

        if $nautilus; then
            log::ok "Nautilus plugin: installed"
        else
            log::warn "Nautilus plugin (not installed)"
        fi

        log::break

        local options=()

        if ! $app || ! $nautilus; then
            options+=("Install Nextcloud")
        fi

        if $app || $nautilus; then
            options+=("Remove Nextcloud")
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
            "Install Nextcloud")
                log::break
                _nextcloud::install
                ;;
            "Remove Nextcloud")
                log::break
                _nextcloud::remove
                ;;
        esac
    done
}

_nextcloud::install() {
    # Flatpak client
    if ! _nextcloud::app_installed; then
        if ! command -v flatpak &>/dev/null; then
            log::error "Flatpak not installed. Install via Package managers first"
            ui::return_or_exit
            return
        fi

        log::info "Installing Nextcloud Desktop"
        if flatpak install -y flathub "$_NEXTCLOUD_FLATPAK_ID"; then
            log::ok "Nextcloud Desktop installed"
        else
            log::error "Failed to install Nextcloud Desktop"
            return
        fi
    else
        log::ok "Nextcloud Desktop: already installed"
    fi

    # Nautilus plugin
    if ! _nextcloud::nautilus_installed; then
        log::info "Installing Nautilus plugin"
        ui::flush_input
        if sudo apt-get install -y "$_NEXTCLOUD_NAUTILUS_PKG" </dev/tty; then
            hash -r
            log::ok "Nautilus plugin installed"
        else
            log::error "Failed to install Nautilus plugin"
        fi
    else
        log::ok "Nautilus plugin: already installed"
    fi
    ui::return_or_exit
}

_nextcloud::remove() {
    if _nextcloud::nautilus_installed; then
        log::info "Removing Nautilus plugin"
        ui::flush_input
        if sudo apt-get remove -y "$_NEXTCLOUD_NAUTILUS_PKG" </dev/tty; then
            hash -r
            log::ok "Nautilus plugin removed"
        else
            log::error "Failed to remove Nautilus plugin"
        fi
    fi

    if _nextcloud::app_installed; then
        log::info "Removing Nextcloud Desktop"
        if flatpak remove -y "$_NEXTCLOUD_FLATPAK_ID"; then
            log::ok "Nextcloud Desktop removed"
        else
            log::error "Failed to remove Nextcloud Desktop"
        fi
    fi
    ui::return_or_exit
}
