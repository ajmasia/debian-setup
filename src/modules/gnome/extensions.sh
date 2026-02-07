# GNOME Shell Extensions task

[[ -n "${_MOD_EXTENSIONS_LOADED:-}" ]] && return 0
_MOD_EXTENSIONS_LOADED=1

_EXTENSIONS_LABEL="Configure Extensions"
_EXTENSIONS_DESC="Install Extension Manager and GNOME Shell extensions."

_EXTENSIONS_MANAGER_PKG="extension-manager"
_EXTENSIONS_LIST_FILE="${SCRIPT_DIR}/packages/gnome/extensions.txt"
_EXTENSIONS_API_BASE="https://extensions.gnome.org"

# ── Helpers ─────────────────────────────────────────────

_extensions::read_list() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        printf '%s\n' "$line"
    done < "$_EXTENSIONS_LIST_FILE"
}

_extensions::manager_installed() {
    dpkg -l "$_EXTENSIONS_MANAGER_PKG" 2>/dev/null | grep -q '^ii'
}

_extensions::is_installed() {
    local uuid="$1"
    gnome-extensions show "$uuid" &>/dev/null
}

_extensions::is_enabled() {
    local uuid="$1"
    gnome-extensions list --enabled 2>/dev/null | grep -qF "$uuid"
}

_extensions::shell_version() {
    gnome-shell --version 2>/dev/null | grep -oP '[\d]+' | head -1
}

# ── Checks ──────────────────────────────────────────────

extensions::check() {
    _extensions::manager_installed || return 1

    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_enabled "$uuid" || return 1
    done < <(_extensions::read_list)

    return 0
}

extensions::status() {
    local pending=0

    _extensions::manager_installed || pending=$((pending + 1))

    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_enabled "$uuid" || pending=$((pending + 1))
    done < <(_extensions::read_list)

    if [[ $pending -gt 0 ]]; then
        printf '%s items pending' "$pending"
    fi
}

# ── Wizard ──────────────────────────────────────────────

extensions::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "GNOME > Extensions"
        log::break

        log::info "GNOME Shell Extensions"

        if _extensions::manager_installed; then
            log::ok "Extension Manager: installed"
        else
            log::warn "Extension Manager: not installed"
        fi

        local uuid label
        while IFS='|' read -r uuid label; do
            if _extensions::is_enabled "$uuid"; then
                log::ok "${label}: enabled"
            elif _extensions::is_installed "$uuid"; then
                log::warn "${label}: installed (not enabled)"
            else
                log::warn "${label}: not installed"
            fi
        done < <(_extensions::read_list)

        log::break

        local options=()
        local all_ok=true
        extensions::check || all_ok=false

        if ! $all_ok; then
            options+=("Install All")
        fi

        local any_enabled=false
        while IFS='|' read -r uuid label; do
            if _extensions::is_enabled "$uuid"; then
                any_enabled=true
                break
            fi
        done < <(_extensions::read_list)

        if $any_enabled; then
            options+=("Disable All Extensions")
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
            "Install All")
                log::break
                _extensions::install_all
                ;;
            "Disable All Extensions")
                log::break
                _extensions::disable_all
                ;;
        esac
    done
}

# ── Install ─────────────────────────────────────────────

_extensions::install_all() {
    if ! command -v gnome-extensions &>/dev/null; then
        log::error "gnome-extensions command not found. Is GNOME Shell installed?"
        return
    fi

    # Install Extension Manager via APT if missing
    if ! _extensions::manager_installed; then
        log::info "Installing Extension Manager"
        ui::flush_input
        if sudo apt-get install -y "$_EXTENSIONS_MANAGER_PKG" </dev/tty; then
            hash -r
            log::ok "Extension Manager installed"
        else
            log::error "Failed to install Extension Manager"
        fi
    else
        log::ok "Extension Manager: already installed"
    fi

    # Get GNOME Shell version
    local shell_ver
    shell_ver="$(_extensions::shell_version)"

    if [[ -z "$shell_ver" ]]; then
        log::error "Could not detect GNOME Shell version"
        return
    fi

    log::info "GNOME Shell version: ${shell_ver}"

    # Install and enable each extension
    local uuid label
    while IFS='|' read -r uuid label; do
        if _extensions::is_enabled "$uuid"; then
            log::ok "${label}: already enabled"
            continue
        fi

        if ! _extensions::is_installed "$uuid"; then
            _extensions::download_and_install "$uuid" "$label" "$shell_ver"
        fi

        if _extensions::is_installed "$uuid"; then
            gnome-extensions enable "$uuid" 2>/dev/null || true
            log::ok "${label}: enabled"
        fi
    done < <(_extensions::read_list)

    log::break
    log::info "Newly installed extensions activate after re-login"
}

_extensions::download_and_install() {
    local uuid="$1" label="$2" shell_ver="$3"

    log::info "Downloading ${label}"

    # Query API for extension info
    local info
    info="$(curl -fsSL "${_EXTENSIONS_API_BASE}/extension-info/?uuid=${uuid}" 2>/dev/null || true)"

    if [[ -z "$info" ]]; then
        log::error "Failed to query API for ${label}"
        return
    fi

    # Extract pk for our shell version
    local pk
    pk="$(printf '%s' "$info" | grep -oP "\"${shell_ver}\"\s*:\s*\{\"pk\"\s*:\s*\K\d+" || true)"

    if [[ -z "$pk" ]]; then
        log::warn "${label}: not available for GNOME Shell ${shell_ver}"
        return
    fi

    # Download zip
    local tmpfile
    tmpfile="$(mktemp --suffix=.zip)"

    local url="${_EXTENSIONS_API_BASE}/download-extension/${uuid}.shell-extension.zip?version_tag=${pk}"

    if ! curl -fsSL "$url" -o "$tmpfile" 2>/dev/null; then
        log::error "Failed to download ${label}"
        rm -f "$tmpfile"
        return
    fi

    # Install
    if gnome-extensions install --force "$tmpfile" 2>/dev/null; then
        log::ok "${label}: files installed"
    else
        log::error "Failed to install ${label}"
    fi

    rm -f "$tmpfile"
}

# ── Disable ─────────────────────────────────────────────

_extensions::disable_all() {
    log::info "Disabling managed extensions"

    local uuid label
    while IFS='|' read -r uuid label; do
        if _extensions::is_enabled "$uuid"; then
            gnome-extensions disable "$uuid" 2>/dev/null || true
            log::ok "${label}: disabled"
        fi
    done < <(_extensions::read_list)
}
