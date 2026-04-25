# Go developer tool task

[[ -n "${_MOD_GO_LOADED:-}" ]] && return 0
_MOD_GO_LOADED=1

_GO_LABEL="Configure Go"
_GO_DESC="Install or remove the Go programming language (APT or official tarball)."

_GO_DL_URL="https://go.dev/dl/"
_GO_INSTALL_DIR="/usr/local/go"

_go::is_installed_apt() {
    dpkg -l golang-go 2>/dev/null | grep -q '^ii'
}

_go::is_installed_manual() {
    [[ -x "${_GO_INSTALL_DIR}/bin/go" ]]
}

_go::is_installed() {
    _go::is_installed_apt || _go::is_installed_manual
}

_go::session_ready() {
    command -v go &>/dev/null
}

_go::install_method() {
    if _go::is_installed_apt; then
        printf 'apt'
    elif _go::is_installed_manual; then
        printf 'manual'
    else
        printf 'none'
    fi
}

go::check() {
    _go::is_installed && _go::session_ready
}

go::status() {
    local issues=()
    _go::is_installed || issues+=("not installed")
    _go::is_installed && ! _go::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

go::apply() {
    local choice

    while true; do
        local installed=false session_ready=false method
        _go::is_installed && installed=true
        _go::session_ready && session_ready=true
        method="$(_go::install_method)"

        ui::clear_content
        log::nav "Development > Environments > Go"
        log::break

        log::info "Current Go configuration"

        if $installed; then
            if $session_ready; then
                local version
                version="$(go version 2>/dev/null || true)"
                log::ok "Go: ${version} (${method})"
            else
                log::ok "Go: installed (${method})"
                log::warn "Restart needed to activate Go in current session"
            fi
        else
            log::warn "Go: not installed"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            options+=("Remove Go")
        else
            options+=("Install Go (APT)" "Install Go (official tarball)")
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
            "Install Go (APT)")
                log::break
                log::info "Installing Go via APT"
                ui::flush_input
                if sudo apt install -y golang-go </dev/tty; then
                    hash -r
                    log::ok "Go installed via APT"
                else
                    log::error "Failed to install Go"
                fi
                ui::return_or_exit
                ;;
            "Install Go (official tarball)")
                log::break
                _go::_install_tarball
                ;;
            "Remove Go")
                log::break
                if [[ "$method" == "apt" ]]; then
                    log::info "Removing Go (APT)"
                    ui::flush_input
                    if sudo apt remove -y golang-go </dev/tty; then
                        hash -r
                        log::ok "Go removed"
                    else
                        log::error "Failed to remove Go"
                    fi
                else
                    log::info "Removing Go (manual installation)"
                    ui::flush_input
                    sudo rm -rf "$_GO_INSTALL_DIR" </dev/tty
                    log::ok "Go directory removed"

                    # Clean PATH from .bashrc
                    if [[ -f "$HOME/.bashrc" ]] && grep -Fq '/usr/local/go/bin' "$HOME/.bashrc"; then
                        local tmp
                        tmp="$(mktemp)"
                        grep -Fv '/usr/local/go/bin' "$HOME/.bashrc" > "$tmp" || true
                        mv "$tmp" "$HOME/.bashrc"
                        log::ok "Cleaned .bashrc"
                    fi

                    hash -r
                    log::ok "Go removed"
                    log::break
                    log::warn "Restart your shell to complete cleanup"
                fi
                ui::return_or_exit
                ;;
        esac
    done
}

_go::_install_tarball() {
    log::info "Fetching latest Go version"

    # Get latest version from go.dev
    local latest
    latest="$(curl -fsSL 'https://go.dev/VERSION?m=text' 2>/dev/null | head -1 || true)"

    if [[ -z "$latest" ]]; then
        log::error "Failed to determine latest Go version"
        ui::return_or_exit
        return
    fi

    log::ok "Latest version: ${latest}"

    local arch
    arch="$(dpkg --print-architecture)"
    # Map Debian arch names to Go arch names
    case "$arch" in
        amd64) arch="amd64" ;;
        arm64) arch="arm64" ;;
        armhf) arch="armv6l" ;;
        i386)  arch="386" ;;
        *)
            log::error "Unsupported architecture: ${arch}"
            ui::return_or_exit
            return
            ;;
    esac

    local tarball="${latest}.linux-${arch}.tar.gz"
    local url="${_GO_DL_URL}${tarball}"

    log::info "Downloading ${tarball}"
    local tmp_file
    tmp_file="$(mktemp)"

    if ! curl -fsSL "$url" -o "$tmp_file"; then
        rm -f "$tmp_file"
        log::error "Failed to download Go tarball"
        ui::return_or_exit
        return
    fi

    log::ok "Download complete"
    log::info "Installing to ${_GO_INSTALL_DIR}"
    ui::flush_input

    # Remove previous installation if exists
    if [[ -d "$_GO_INSTALL_DIR" ]]; then
        sudo rm -rf "$_GO_INSTALL_DIR" </dev/tty
    fi

    sudo tar -C /usr/local -xzf "$tmp_file" </dev/tty
    rm -f "$tmp_file"
    log::ok "Go extracted to ${_GO_INSTALL_DIR}"

    # Add to PATH in .bashrc if not already present
    if [[ -f "$HOME/.bashrc" ]] && ! grep -Fq '/usr/local/go/bin' "$HOME/.bashrc"; then
        printf '\n# Go\nexport PATH="/usr/local/go/bin:$PATH"\n' >> "$HOME/.bashrc"
        log::ok "Added Go to PATH in .bashrc"
    fi

    hash -r
    log::break
    log::ok "Go installed (${latest})"
    log::break
    log::warn "Restart your shell or run: export PATH=\"/usr/local/go/bin:\$PATH\""
    ui::return_or_exit
}
