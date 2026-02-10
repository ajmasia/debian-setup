# Nextcloud Desktop task (Flatpak / APT + Nautilus plugin)

[[ -n "${_MOD_NEXTCLOUD_LOADED:-}" ]] && return 0
_MOD_NEXTCLOUD_LOADED=1

_NEXTCLOUD_LABEL="Configure Nextcloud"
_NEXTCLOUD_DESC="Install Nextcloud Desktop client and Nautilus integration."

_NEXTCLOUD_FLATPAK_ID="com.nextcloud.desktopclient.nextcloud"
_NEXTCLOUD_APT_PKG="nextcloud-desktop"
_NEXTCLOUD_NAUTILUS_PKG="nautilus-nextcloud"

_nextcloud::flatpak_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_NEXTCLOUD_FLATPAK_ID"
}

_nextcloud::apt_installed() {
    dpkg -l "$_NEXTCLOUD_APT_PKG" 2>/dev/null | grep -q '^ii'
}

_nextcloud::nautilus_installed() {
    dpkg -l "$_NEXTCLOUD_NAUTILUS_PKG" 2>/dev/null | grep -q '^ii'
}

nextcloud::check() {
    { _nextcloud::flatpak_installed || _nextcloud::apt_installed; } && _nextcloud::nautilus_installed
}

nextcloud::status() {
    local missing=()
    _nextcloud::flatpak_installed || _nextcloud::apt_installed || missing+=("client")
    _nextcloud::nautilus_installed || missing+=("nautilus plugin")
    if [[ ${#missing[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s not installed' "${missing[*]}"
    fi
}

nextcloud::apply() {
    local choice

    while true; do
        local fp=false apt=false nautilus=false
        _nextcloud::flatpak_installed && fp=true
        _nextcloud::apt_installed && apt=true
        _nextcloud::nautilus_installed && nautilus=true

        ui::clear_content
        log::nav "Software > Productivity > Nextcloud"
        log::break

        log::info "Nextcloud Desktop"

        if $fp; then
            local version
            version="$(flatpak info "$_NEXTCLOUD_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Nextcloud Desktop (Flatpak): ${version}"
        fi

        if $apt; then
            local version
            version="$(dpkg -l "$_NEXTCLOUD_APT_PKG" 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "Nextcloud Desktop (APT): ${version}"
        fi

        if ! $fp && ! $apt; then
            log::warn "Nextcloud Desktop (not installed)"
        fi

        if $nautilus; then
            log::ok "Nautilus plugin: installed"
        else
            log::warn "Nautilus plugin (not installed)"
        fi

        log::break

        local options=()

        if ! $fp && ! $apt; then
            options+=("Install via Flatpak" "Install via APT")
        fi

        $fp && options+=("Remove Nextcloud (Flatpak)")
        $apt && options+=("Remove Nextcloud (APT)")

        if $nautilus; then
            options+=("Remove Nautilus plugin")
        else
            options+=("Install Nautilus plugin")
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
            "Install via Flatpak")
                log::break
                _nextcloud::install_flatpak
                ;;
            "Install via APT")
                log::break
                _nextcloud::install_apt
                ;;
            "Remove Nextcloud (Flatpak)")
                log::break
                _nextcloud::remove_flatpak
                ;;
            "Remove Nextcloud (APT)")
                log::break
                _nextcloud::remove_apt
                ;;
            "Install Nautilus plugin")
                log::break
                _nextcloud::install_nautilus
                ;;
            "Remove Nautilus plugin")
                log::break
                _nextcloud::remove_nautilus
                ;;
        esac
    done
}

_nextcloud::install_flatpak() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Nextcloud Desktop (Flatpak)"
    if sudo flatpak install -y flathub "$_NEXTCLOUD_FLATPAK_ID"; then
        log::ok "Nextcloud Desktop (Flatpak) installed"
    else
        log::error "Failed to install Nextcloud Desktop (Flatpak)"
    fi
    ui::return_or_exit
}

_nextcloud::install_apt() {
    log::info "Installing Nextcloud Desktop (APT)"
    ui::flush_input
    if sudo apt-get install -y "$_NEXTCLOUD_APT_PKG" </dev/tty; then
        hash -r
        log::ok "Nextcloud Desktop (APT) installed"
    else
        log::error "Failed to install Nextcloud Desktop (APT)"
    fi
    ui::return_or_exit
}

_nextcloud::install_nautilus() {
    log::info "Installing Nautilus plugin"
    ui::flush_input
    if sudo apt-get install -y "$_NEXTCLOUD_NAUTILUS_PKG" </dev/tty; then
        hash -r
        log::ok "Nautilus plugin installed"
    else
        log::error "Failed to install Nautilus plugin"
    fi
    ui::return_or_exit
}

_nextcloud::remove_flatpak() {
    log::info "Removing Nextcloud Desktop (Flatpak)"
    if sudo flatpak remove -y "$_NEXTCLOUD_FLATPAK_ID"; then
        log::ok "Nextcloud Desktop (Flatpak) removed"
    else
        log::error "Failed to remove Nextcloud Desktop (Flatpak)"
    fi
    ui::return_or_exit
}

_nextcloud::remove_apt() {
    log::info "Removing Nextcloud Desktop (APT)"
    ui::flush_input
    if sudo apt-get remove -y "$_NEXTCLOUD_APT_PKG" </dev/tty; then
        hash -r
        log::ok "Nextcloud Desktop (APT) removed"
    else
        log::error "Failed to remove Nextcloud Desktop (APT)"
    fi
    ui::return_or_exit
}

_nextcloud::remove_nautilus() {
    log::info "Removing Nautilus plugin"
    ui::flush_input
    if sudo apt-get remove -y "$_NEXTCLOUD_NAUTILUS_PKG" </dev/tty; then
        hash -r
        log::ok "Nautilus plugin removed"
    else
        log::error "Failed to remove Nautilus plugin"
    fi
    ui::return_or_exit
}
