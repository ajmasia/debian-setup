# Zellij terminal multiplexer task

[[ -n "${_MOD_ZELLIJ_LOADED:-}" ]] && return 0
_MOD_ZELLIJ_LOADED=1

_ZELLIJ_LABEL="Configure Zellij"
_ZELLIJ_DESC="Install or remove Zellij terminal multiplexer."

_ZELLIJ_API="https://api.github.com/repos/zellij-org/zellij/releases/latest"
_ZELLIJ_BIN="$HOME/.local/bin/zellij"

_zellij::is_installed() {
    [[ -x "$_ZELLIJ_BIN" ]]
}

_zellij::session_ready() {
    command -v zellij &>/dev/null
}

zellij::check() {
    _zellij::is_installed && _zellij::session_ready
}

zellij::status() {
    local issues=()
    _zellij::is_installed || issues+=("not installed")
    _zellij::is_installed && ! _zellij::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

zellij::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _zellij::is_installed && installed=true
        _zellij::session_ready && session_ready=true

        ui::clear_content
        log::nav "Shell > Zellij"
        log::break

        log::info "Zellij"

        if $installed; then
            if $session_ready; then
                local version
                version="$(zellij --version 2>/dev/null || true)"
                log::ok "Zellij: ${version}"
            else
                log::ok "Zellij: installed"
                log::warn "Restart needed to activate zellij in current session"
            fi
        else
            log::warn "Zellij (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Zellij" "Remove Zellij")
        else
            options+=("Install Zellij")
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
            "Install Zellij"|"Update Zellij")
                log::break
                _zellij::install
                ;;
            "Remove Zellij")
                log::break
                _zellij::remove
                ;;
        esac
    done
}

_zellij::install() {
    log::info "Fetching latest Zellij version"

    local json version
    json="$(curl -fsSL "$_ZELLIJ_API" 2>/dev/null || true)"

    if [[ -z "$json" ]]; then
        log::error "Failed to fetch Zellij release info"
        return
    fi

    version="$(printf '%s' "$json" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"

    if [[ -z "$version" ]]; then
        log::error "Failed to parse Zellij version"
        return
    fi

    log::ok "Latest version: ${version}"

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)
            log::error "Unsupported architecture: ${arch}"
            return
            ;;
    esac

    local url="https://github.com/zellij-org/zellij/releases/download/v${version}/zellij-${arch}-unknown-linux-musl.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Downloading Zellij ${version}"
    if ! curl -fsSL -o "$tmpdir/zellij.tar.gz" "$url"; then
        log::error "Failed to download Zellij"
        rm -rf "$tmpdir"
        return
    fi

    tar -xzf "$tmpdir/zellij.tar.gz" -C "$tmpdir"

    mkdir -p "$HOME/.local/bin"
    mv "$tmpdir/zellij" "$_ZELLIJ_BIN"
    chmod 755 "$_ZELLIJ_BIN"
    rm -rf "$tmpdir"
    hash -r

    log::ok "Zellij ${version} installed"

    # PATH warning
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

_zellij::remove() {
    log::info "Removing Zellij"

    rm -f "$_ZELLIJ_BIN"
    hash -r

    log::ok "Zellij removed"
}
