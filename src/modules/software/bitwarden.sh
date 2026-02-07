# Bitwarden CLI task

[[ -n "${_MOD_BITWARDEN_LOADED:-}" ]] && return 0
_MOD_BITWARDEN_LOADED=1

_BITWARDEN_LABEL="Configure Bitwarden CLI"
_BITWARDEN_DESC="Install Bitwarden CLI."
_BITWARDEN_ZIP_URL="https://vault.bitwarden.com/download/?app=cli&platform=linux"
_BITWARDEN_BIN="$HOME/.local/bin/bw"

_bitwarden::is_installed_npm() {
    command -v bw &>/dev/null && [[ "$(npm list -g @bitwarden/cli 2>/dev/null)" == *"@bitwarden/cli"* ]]
}

_bitwarden::is_installed_bin() {
    [[ -x "$_BITWARDEN_BIN" ]]
}

_bitwarden::is_installed() {
    _bitwarden::is_installed_npm 2>/dev/null || _bitwarden::is_installed_bin
}

bitwarden::check() {
    _bitwarden::is_installed
}

bitwarden::status() {
    _bitwarden::is_installed || printf 'not installed'
}

bitwarden::apply() {
    local choice

    while true; do
        local installed=false
        _bitwarden::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Security > Password Managers > Bitwarden CLI"
        log::break

        log::info "Bitwarden CLI"

        if $installed; then
            local version
            version="$(bw --version 2>/dev/null || true)"
            log::ok "Bitwarden CLI: ${version}"
        else
            log::warn "Bitwarden CLI (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Bitwarden CLI")
        else
            if command -v npm &>/dev/null; then
                options+=("Install via npm" "Install binary")
            else
                options+=("Install binary")
            fi
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
            "Install via npm")
                log::break
                _bitwarden::install_npm
                ;;
            "Install binary")
                log::break
                _bitwarden::install_bin
                ;;
            "Remove Bitwarden CLI")
                log::break
                _bitwarden::remove
                ;;
        esac
    done
}

_bitwarden::install_npm() {
    log::info "Installing Bitwarden CLI via npm"
    if npm install -g @bitwarden/cli; then
        hash -r
        log::ok "Bitwarden CLI installed"
    else
        log::error "Failed to install Bitwarden CLI"
    fi
}

_bitwarden::install_bin() {
    log::info "Downloading Bitwarden CLI"

    if ! command -v unzip &>/dev/null; then
        log::error "unzip is required. Install CLI utilities first"
        return
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! wget -qO "$tmpdir/bw.zip" "$_BITWARDEN_ZIP_URL"; then
        log::error "Failed to download Bitwarden CLI"
        rm -rf "$tmpdir"
        return
    fi

    unzip -q "$tmpdir/bw.zip" -d "$tmpdir"
    mkdir -p "$HOME/.local/bin"
    mv "$tmpdir/bw" "$_BITWARDEN_BIN"
    chmod +x "$_BITWARDEN_BIN"
    rm -rf "$tmpdir"
    hash -r

    log::ok "Bitwarden CLI installed"

    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

_bitwarden::remove() {
    if _bitwarden::is_installed_npm 2>/dev/null; then
        log::info "Removing Bitwarden CLI (npm)"
        if npm uninstall -g @bitwarden/cli; then
            hash -r
            log::ok "Bitwarden CLI removed"
        else
            log::error "Failed to remove Bitwarden CLI"
        fi
    elif _bitwarden::is_installed_bin; then
        log::info "Removing Bitwarden CLI (binary)"
        rm -f "$_BITWARDEN_BIN"
        hash -r
        log::ok "Bitwarden CLI removed"
    fi
}
