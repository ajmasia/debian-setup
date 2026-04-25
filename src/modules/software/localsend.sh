# LocalSend task

[[ -n "${_MOD_LOCALSEND_LOADED:-}" ]] && return 0
_MOD_LOCALSEND_LOADED=1

_LOCALSEND_LABEL="Configure LocalSend"
_LOCALSEND_DESC="Install LocalSend for local network file sharing."
_LOCALSEND_GH_API="https://api.github.com/repos/localsend/localsend/releases/latest"
_LOCALSEND_PKG="localsend"
_LOCALSEND_DEP="gir1.2-ayatanaappindicator3-0.1"

_localsend::is_installed() {
    dpkg -l "$_LOCALSEND_PKG" 2>/dev/null | grep -q '^ii'
}

localsend::check() {
    _localsend::is_installed
}

localsend::status() {
    _localsend::is_installed || printf 'not installed'
}

localsend::apply() {
    local choice

    while true; do
        local installed=false
        _localsend::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Productivity > LocalSend"
        log::break

        log::info "LocalSend"

        if $installed; then
            local version
            version="$(dpkg -l "$_LOCALSEND_PKG" 2>/dev/null | awk '/^ii/{print $3}' || true)"
            log::ok "LocalSend: ${version}"
        else
            log::warn "LocalSend (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update LocalSend" "Remove LocalSend")
        else
            options+=("Install LocalSend")
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
            "Install LocalSend"|"Update LocalSend")
                log::break
                _localsend::install
                ;;
            "Remove LocalSend")
                log::break
                _localsend::remove
                ;;
        esac
    done
}

_localsend::install() {
    log::info "Fetching latest LocalSend version"

    local json version
    json="$(curl -fsSL "$_LOCALSEND_GH_API" 2>/dev/null || true)"

    if [[ -z "$json" ]]; then
        log::error "Failed to fetch LocalSend release info"
        ui::return_or_exit
        return
    fi

    version="$(printf '%s' "$json" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"

    if [[ -z "$version" ]]; then
        log::error "Failed to parse LocalSend version"
        ui::return_or_exit
        return
    fi

    log::ok "Latest version: ${version}"

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64) arch="x86-64" ;;
        aarch64) arch="arm-64" ;;
        *)
            log::error "Unsupported architecture: ${arch}"
            ui::return_or_exit
            return
            ;;
    esac

    local url="https://github.com/localsend/localsend/releases/download/v${version}/LocalSend-${version}-linux-${arch}.deb"

    log::info "Installing dependency: ${_LOCALSEND_DEP}"
    ui::flush_input
    if ! sudo apt-get install -y "$_LOCALSEND_DEP" </dev/tty; then
        log::error "Failed to install dependency: ${_LOCALSEND_DEP}"
        ui::return_or_exit
        return
    fi

    log::info "Downloading LocalSend ${version}"

    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    if ! wget -qO "$tmpfile" "$url"; then
        log::error "Failed to download LocalSend"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi

    log::info "Installing LocalSend ${version}"
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::ok "LocalSend ${version} installed"
    else
        log::error "Failed to install LocalSend"
    fi
    rm -f "$tmpfile"
    ui::return_or_exit
}

_localsend::remove() {
    log::info "Removing LocalSend"
    ui::flush_input
    if sudo apt-get remove -y "$_LOCALSEND_PKG" </dev/tty; then
        hash -r
        log::ok "LocalSend removed"
    else
        log::error "Failed to remove LocalSend"
    fi
    ui::return_or_exit
}
