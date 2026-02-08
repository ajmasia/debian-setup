# GNOME Shell Extensions task

[[ -n "${_MOD_EXTENSIONS_LOADED:-}" ]] && return 0
_MOD_EXTENSIONS_LOADED=1

_EXTENSIONS_LABEL="Configure Extensions"
_EXTENSIONS_DESC="Manage GNOME Shell extensions."

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

_extensions::shell_version() {
    gnome-shell --version 2>/dev/null | grep -oP '[\d]+' | head -1
}

# ── Checks ──────────────────────────────────────────────

extensions::check() {
    _extensions::refresh
    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_enabled "$uuid" || return 1
    done < <(_extensions::read_list)

    return 0
}

extensions::status() {
    local pending=0

    _extensions::refresh
    local uuid label
    while IFS='|' read -r uuid label; do
        _extensions::is_enabled "$uuid" || pending=$((pending + 1))
    done < <(_extensions::read_list)

    if [[ $pending -gt 0 ]]; then
        printf '%s extensions pending' "$pending"
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

        _extensions::refresh
        local uuid label
        local ext_total=0 ext_enabled=0
        while IFS='|' read -r uuid label; do
            ext_total=$((ext_total + 1))
            _extensions::is_enabled "$uuid" && ext_enabled=$((ext_enabled + 1))
        done < <(_extensions::read_list)

        if [[ $ext_enabled -eq $ext_total ]]; then
            log::ok "Extensions: ${ext_enabled}/${ext_total} enabled"
        else
            log::warn "Extensions: ${ext_enabled}/${ext_total} enabled"
        fi

        log::break

        local options=()

        options+=("Show extensions")

        if [[ $ext_enabled -lt $ext_total ]]; then
            options+=("Install all pending" "Select extensions to install")
        fi

        if [[ $ext_enabled -gt 0 ]]; then
            options+=("Disable extensions")
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
            "Disable extensions")
                log::break
                _extensions::ext_select_disable
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

    local uuid label
    local count=0

    while IFS='|' read -r uuid label; do
        if _extensions::is_enabled "$uuid"; then
            log::ok "${label}: already enabled"
            continue
        fi

        if ! _extensions::is_installed "$uuid" && ! gnome-extensions show "$uuid" &>/dev/null; then
            _extensions::download_and_install "$uuid" "$label" "$shell_ver"
        fi

        if gnome-extensions show "$uuid" &>/dev/null; then
            gnome-extensions enable "$uuid" 2>/dev/null || true
            log::ok "${label}: enabled"
            count=$((count + 1))
        fi
    done < <(_extensions::read_list)

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} extension(s) installed"
        log::info "Newly installed extensions activate after re-login"
    fi
}

# ── Select install ───────────────────────────────────────

_extensions::ext_select_install() {
    local uuid label
    local pending_labels=()
    local -A id_map=()

    while IFS='|' read -r uuid label; do
        if ! _extensions::is_enabled "$uuid"; then
            local display="${label} (${uuid})"
            pending_labels+=("$display")
            id_map["$display"]="$uuid"
        fi
    done < <(_extensions::read_list)

    if [[ ${#pending_labels[@]} -eq 0 ]]; then
        log::ok "All extensions already enabled"
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

        if ! gnome-extensions show "$ext_uuid" &>/dev/null; then
            _extensions::download_and_install "$ext_uuid" "$display" "$shell_ver"
        fi

        if gnome-extensions show "$ext_uuid" &>/dev/null; then
            gnome-extensions enable "$ext_uuid" 2>/dev/null || true
            log::ok "${display}: enabled"
        fi
    done <<< "$selected"
}

# ── Disable ──────────────────────────────────────────────

_extensions::ext_select_disable() {
    local uuid label
    local enabled_labels=()
    local -A id_map=()

    while IFS='|' read -r uuid label; do
        if _extensions::is_enabled "$uuid"; then
            local display="${label} (${uuid})"
            enabled_labels+=("$display")
            id_map["$display"]="$uuid"
        fi
    done < <(_extensions::read_list)

    if [[ ${#enabled_labels[@]} -eq 0 ]]; then
        log::ok "No extensions enabled"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select extensions to disable:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${enabled_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display ext_uuid
    while IFS= read -r display; do
        ext_uuid="${id_map[$display]}"
        gnome-extensions disable "$ext_uuid" 2>/dev/null || true
        log::ok "${display}: disabled"
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
        return
    fi

    # Extract pk for our shell version
    local escaped_ver="${shell_ver//./\\.}"
    local pk
    pk="$(printf '%s' "$info" | grep -oP "\"${escaped_ver}\"\s*:\s*\{\"pk\"\s*:\s*\K\d+" || true)"

    if [[ -z "$pk" ]]; then
        log::warn "${label}: not available for GNOME Shell ${shell_ver}"
        return
    fi

    # Download zip
    local tmpfile
    tmpfile="$(mktemp --suffix=.zip)"
    trap "rm -f '$tmpfile'" RETURN

    local url="${_EXTENSIONS_API_BASE}/download-extension/${uuid}.shell-extension.zip?version_tag=${pk}"

    if ! curl -fsSL "$url" -o "$tmpfile" 2>/dev/null; then
        log::error "Failed to download ${label}"
        return
    fi

    # Install
    if gnome-extensions install --force "$tmpfile" 2>/dev/null; then
        log::ok "${label}: files installed"
    else
        log::error "Failed to install ${label}"
    fi
}
