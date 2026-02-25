# GNOME Shell Extensions task

[[ -n "${_MOD_EXTENSIONS_LOADED:-}" ]] && return 0
_MOD_EXTENSIONS_LOADED=1

_EXTENSIONS_LABEL="Configure Extensions"
_EXTENSIONS_DESC="Manage GNOME Shell extensions."

_EXTENSIONS_LIST_FILE="${SCRIPT_DIR}/packages/gnome/extensions.txt"
_EXTENSIONS_API_BASE="https://extensions.gnome.org"
_EXTENSIONS_APP_PKG="gnome-shell-extension-prefs"
_EXTENSIONS_MGR_PKG="gnome-shell-extension-manager"

# ── Helpers ─────────────────────────────────────────────

_extensions::pkg_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}

_extensions::apt_install() {
    local pkg="$1" label="$2"
    log::info "Installing ${label}"
    ui::flush_input
    if sudo apt-get install -y "$pkg" </dev/tty; then
        hash -r
        log::ok "${label} installed"
    else
        log::error "Failed to install ${label}"
    fi
}

_extensions::apt_remove() {
    local pkg="$1" label="$2"
    log::info "Removing ${label}"
    ui::flush_input
    if sudo apt-get remove -y "$pkg" </dev/tty; then
        hash -r
        log::ok "${label} removed"
    else
        log::error "Failed to remove ${label}"
    fi
}

_extensions::read_list() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        printf '%s\n' "$line"
    done < "$_EXTENSIONS_LIST_FILE"
}

# Extension cache (avoids repeated gnome-extensions calls)
_EXTENSIONS_INSTALLED_CACHE=""
_EXTENSIONS_ENABLED_CACHE=""

_extensions::refresh() {
    _EXTENSIONS_INSTALLED_CACHE="$(gnome-extensions list 2>/dev/null || true)"
    _EXTENSIONS_ENABLED_CACHE="$(gnome-extensions list --enabled 2>/dev/null || true)"
}

_extensions::is_installed() {
    local uuid="$1"
    printf '%s\n' "$_EXTENSIONS_INSTALLED_CACHE" | grep -qF "$uuid"
}

_extensions::is_enabled() {
    local uuid="$1"
    printf '%s\n' "$_EXTENSIONS_ENABLED_CACHE" | grep -qF "$uuid"
}

_extensions::gsettings_disable() {
    local uuid="$1"
    local current
    current="$(gsettings get org.gnome.shell enabled-extensions)"
    [[ "$current" != *"'${uuid}'"* ]] && return 0
    # Remove uuid from the list
    local new_list
    new_list="$(printf '%s' "$current" | sed "s/, *'${uuid}'//; s/'${uuid}', *//; s/'${uuid}'//")"
    gsettings set org.gnome.shell enabled-extensions "$new_list"
}

_extensions::shell_version() {
    gnome-shell --version 2>/dev/null | grep -oP '[\d]+' | head -1
}

# ── Checks ──────────────────────────────────────────────

extensions::check() {
    _extensions::pkg_installed "$_EXTENSIONS_APP_PKG" || return 1
    _extensions::refresh
    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_installed "$uuid" || return 1
    done < <(_extensions::read_list)

    return 0
}

extensions::status() {
    local issues=()
    _extensions::pkg_installed "$_EXTENSIONS_APP_PKG" || issues+=("Extensions app not installed")

    local pending=0
    _extensions::refresh
    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_installed "$uuid" || pending=$((pending + 1))
    done < <(_extensions::read_list)

    [[ $pending -gt 0 ]] && issues+=("${pending} not installed")

    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

# ── Wizard ──────────────────────────────────────────────

extensions::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "GNOME > Extensions"
        log::break

        log::info "Shell Extensions"

        if _extensions::pkg_installed "$_EXTENSIONS_APP_PKG"; then
            log::ok "Extensions app: installed"
        else
            log::warn "Extensions app: not installed"
        fi

        if _extensions::pkg_installed "$_EXTENSIONS_MGR_PKG"; then
            log::ok "Extension Manager: installed"
        else
            log::warn "Extension Manager: not installed"
        fi

        _extensions::refresh
        local uuid label
        local ext_total=0 ext_installed=0
        while IFS='|' read -r uuid label; do
            ext_total=$((ext_total + 1))
            _extensions::is_installed "$uuid" && ext_installed=$((ext_installed + 1))
        done < <(_extensions::read_list)

        if [[ $ext_installed -eq $ext_total ]]; then
            log::ok "Extensions: ${ext_installed}/${ext_total} installed"
        else
            log::warn "Extensions: ${ext_installed}/${ext_total} installed"
        fi

        log::break

        local options=()

        if _extensions::pkg_installed "$_EXTENSIONS_APP_PKG"; then
            options+=("Remove Extensions app")
        else
            options+=("Install Extensions app")
        fi
        if _extensions::pkg_installed "$_EXTENSIONS_MGR_PKG"; then
            options+=("Remove Extension Manager")
        else
            options+=("Install Extension Manager")
        fi

        options+=("Show extensions")

        if [[ $ext_installed -lt $ext_total ]]; then
            options+=("Install all pending" "Select extensions to install")
        fi
        if [[ $ext_installed -gt 0 ]]; then
            options+=("Uninstall extensions")
        fi

        options+=("Edit extensions list")
        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
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
            "Install Extensions app")
                log::break
                _extensions::apt_install "$_EXTENSIONS_APP_PKG" "Extensions app"
                ;;
            "Remove Extensions app")
                log::break
                _extensions::apt_remove "$_EXTENSIONS_APP_PKG" "Extensions app"
                ;;
            "Install Extension Manager")
                log::break
                _extensions::apt_install "$_EXTENSIONS_MGR_PKG" "Extension Manager"
                ;;
            "Remove Extension Manager")
                log::break
                _extensions::apt_remove "$_EXTENSIONS_MGR_PKG" "Extension Manager"
                ;;
            "Show extensions")
                log::break
                _extensions::ext_show
                ;;
            "Install all pending")
                log::break
                _extensions::ext_install_pending
                ;;
            "Select extensions to install")
                log::break
                _extensions::ext_select_install
                ;;
            "Uninstall extensions")
                log::break
                _extensions::ext_select_uninstall
                ;;
            "Edit extensions list")
                "${EDITOR:-vi}" "$_EXTENSIONS_LIST_FILE" </dev/tty
                ;;
        esac
    done
}

# ── Show ─────────────────────────────────────────────────

_extensions::ext_show() {
    local uuid label
    while IFS='|' read -r uuid label; do
        if _extensions::is_enabled "$uuid"; then
            log::ok "${label} (${uuid})"
        elif _extensions::is_installed "$uuid"; then
            log::warn "${label} (${uuid}) — installed, not enabled"
        else
            log::warn "${label} (${uuid}) — not installed"
        fi
    done < <(_extensions::read_list)

    ui::return_or_exit
}

# ── Install pending ──────────────────────────────────────

_extensions::ext_install_pending() {
    local shell_ver
    shell_ver="$(_extensions::shell_version)"

    if [[ -z "$shell_ver" ]]; then
        log::error "Could not detect GNOME Shell version"
        return
    fi

    log::info "GNOME Shell version: ${shell_ver}"
    _extensions::refresh

    local uuid label
    local count=0 errors=0

    while IFS='|' read -r uuid label; do
        if _extensions::is_installed "$uuid"; then
            log::ok "${label}: already installed"
            continue
        fi

        if _extensions::download_and_install "$uuid" "$label" "$shell_ver"; then
            _extensions::gsettings_disable "$uuid"
            count=$((count + 1))
        else
            errors=$((errors + 1))
        fi
    done < <(_extensions::read_list)

    log::break
    if [[ $count -gt 0 ]]; then
        log::ok "${count} extension(s) installed"
        log::warn "Log out and back in, then enable from Extensions app"
    fi
    if [[ $errors -gt 0 ]]; then
        log::warn "${errors} extension(s) failed"
    fi

    log::break
    gum::choose \
        --header "Press Enter to continue" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "OK"
}

# ── Select install ───────────────────────────────────────

_extensions::ext_select_install() {
    local uuid label
    local pending_labels=()
    local -A id_map=()

    _extensions::refresh
    while IFS='|' read -r uuid label; do
        if ! _extensions::is_installed "$uuid"; then
            local display="${label} (${uuid})"
            pending_labels+=("$display")
            id_map["$display"]="$uuid"
        fi
    done < <(_extensions::read_list)

    if [[ ${#pending_labels[@]} -eq 0 ]]; then
        log::ok "All extensions already installed"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select extensions to install:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local shell_ver
    shell_ver="$(_extensions::shell_version)"

    if [[ -z "$shell_ver" ]]; then
        log::error "Could not detect GNOME Shell version"
        return
    fi

    local display ext_uuid
    while IFS= read -r display; do
        ext_uuid="${id_map[$display]}"
        if _extensions::download_and_install "$ext_uuid" "$display" "$shell_ver"; then
            _extensions::gsettings_disable "$ext_uuid"
        fi
    done <<< "$selected"

    log::break
    log::warn "Log out and back in, then enable from Extensions app"
}

# ── Uninstall ────────────────────────────────────────────

_extensions::ext_select_uninstall() {
    local uuid label
    local installed_labels=()
    local -A id_map=()

    _extensions::refresh
    while IFS='|' read -r uuid label; do
        if _extensions::is_installed "$uuid" || gnome-extensions show "$uuid" &>/dev/null; then
            local display="${label} (${uuid})"
            installed_labels+=("$display")
            id_map["$display"]="$uuid"
        fi
    done < <(_extensions::read_list)

    if [[ ${#installed_labels[@]} -eq 0 ]]; then
        log::ok "No extensions installed"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select extensions to uninstall:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${installed_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display ext_uuid
    while IFS= read -r display; do
        ext_uuid="${id_map[$display]}"
        gnome-extensions uninstall "$ext_uuid" 2>/dev/null || true
        log::ok "${display}: uninstalled"
    done <<< "$selected"
}

# ── Download and install (from GNOME extensions API) ─────

_extensions::download_and_install() {
    local uuid="$1" label="$2" shell_ver="$3"

    log::info "Downloading ${label}"

    # Query API for extension info
    local info
    info="$(curl -fsSL "${_EXTENSIONS_API_BASE}/extension-info/?uuid=${uuid}" 2>/dev/null || true)"

    if [[ -z "$info" ]]; then
        log::error "Failed to query API for ${label}"
        return 1
    fi

    # Extract pk for our shell version
    local escaped_ver="${shell_ver//./\\.}"
    local pk
    pk="$(printf '%s' "$info" | grep -oP "\"${escaped_ver}\"\s*:\s*\{\"pk\"\s*:\s*\K\d+" || true)"

    if [[ -z "$pk" ]]; then
        log::warn "${label}: not available for GNOME Shell ${shell_ver}"
        return 1
    fi

    # Download zip
    local tmpfile
    tmpfile="$(mktemp --suffix=.zip)"
    trap "rm -f '$tmpfile'" RETURN

    local url="${_EXTENSIONS_API_BASE}/download-extension/${uuid}.shell-extension.zip?version_tag=${pk}"

    if ! curl -fsSL "$url" -o "$tmpfile" 2>/dev/null; then
        log::error "Failed to download ${label}"
        return 1
    fi

    # Install
    if gnome-extensions install --force "$tmpfile" 2>/dev/null; then
        log::ok "${label}: installed"
    else
        log::error "Failed to install ${label}"
        return 1
    fi
}
