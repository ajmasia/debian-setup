# Nerd Fonts software task

[[ -n "${_MOD_NERDFONTS_LOADED:-}" ]] && return 0
_MOD_NERDFONTS_LOADED=1

_NERDFONTS_LABEL="Configure Nerd Fonts"
_NERDFONTS_DESC="Install Nerd Fonts families."
_NERDFONTS_BASE_URL="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"
_NERDFONTS_DIR="$HOME/.local/share/fonts"
_NERDFONTS_LIST="${SCRIPT_DIR}/packages/fonts/nerdfonts.txt"

# ── Helpers ─────────────────────────────────────────────

_nerdfonts::read_list() {
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        printf '%s\n' "$line"
    done < "$_NERDFONTS_LIST"
}

_nerdfonts::is_font_installed() {
    local archive="$1"
    local dir="${_NERDFONTS_DIR}/${archive}"
    [[ -d "$dir" ]] && { ls "$dir"/*.ttf &>/dev/null || ls "$dir"/*.otf &>/dev/null; }
}

# ── Public API ──────────────────────────────────────────

nerdfonts::check() {
    local archive label
    while IFS='|' read -r archive label; do
        _nerdfonts::is_font_installed "$archive" || return 1
    done < <(_nerdfonts::read_list)
    return 0
}

nerdfonts::status() {
    local pending=0
    local archive label
    while IFS='|' read -r archive label; do
        _nerdfonts::is_font_installed "$archive" || pending=$((pending + 1))
    done < <(_nerdfonts::read_list)
    if [[ $pending -gt 0 ]]; then
        printf '%s fonts pending' "$pending"
    fi
}

# ── Wizard ──────────────────────────────────────────────

nerdfonts::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "UI and Theming > Fonts > Nerd Fonts"
        log::break

        log::info "Nerd Fonts"

        local archive label
        local font_total=0 font_installed=0
        while IFS='|' read -r archive label; do
            font_total=$((font_total + 1))
            _nerdfonts::is_font_installed "$archive" && font_installed=$((font_installed + 1))
        done < <(_nerdfonts::read_list)

        if [[ $font_installed -eq $font_total ]]; then
            log::ok "Fonts: ${font_installed}/${font_total} installed"
        else
            log::warn "Fonts: ${font_installed}/${font_total} installed"
        fi

        log::break

        local options=()

        options+=("Show fonts")

        if [[ $font_installed -lt $font_total ]]; then
            options+=("Install all pending" "Select fonts to install")
        fi

        if [[ $font_installed -gt 0 ]]; then
            options+=("Remove fonts")
        fi

        options+=("Edit font list")
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
            "Show fonts")
                log::break
                _nerdfonts::show
                ;;
            "Install all pending")
                log::break
                _nerdfonts::install_pending
                ;;
            "Select fonts to install")
                log::break
                _nerdfonts::select_install
                ;;
            "Remove fonts")
                log::break
                _nerdfonts::select_remove
                ;;
            "Edit font list")
                "${EDITOR:-vi}" "$_NERDFONTS_LIST" </dev/tty
                ;;
        esac
    done
}

# ── Show ────────────────────────────────────────────────

_nerdfonts::show() {
    local archive label
    while IFS='|' read -r archive label; do
        if _nerdfonts::is_font_installed "$archive"; then
            log::ok "${label} (${archive})"
        else
            log::warn "${label} (${archive}) — not installed"
        fi
    done < <(_nerdfonts::read_list)

    ui::return_or_exit
}

# ── Install pending ─────────────────────────────────────

_nerdfonts::install_pending() {
    local archive label
    local count=0

    while IFS='|' read -r archive label; do
        if ! _nerdfonts::is_font_installed "$archive"; then
            _nerdfonts::download_font "$archive" "$label"
            _nerdfonts::is_font_installed "$archive" && count=$((count + 1))
        fi
    done < <(_nerdfonts::read_list)

    if [[ $count -gt 0 ]]; then
        log::break
        log::info "Updating font cache"
        fc-cache -f 2>/dev/null || true
        log::ok "${count} font(s) installed"
    fi
}

# ── Select install ──────────────────────────────────────

_nerdfonts::select_install() {
    local archive label
    local pending_labels=()
    local -A archive_map=()

    while IFS='|' read -r archive label; do
        if ! _nerdfonts::is_font_installed "$archive"; then
            local display="${label} (${archive})"
            pending_labels+=("$display")
            archive_map["$display"]="$archive"
        fi
    done < <(_nerdfonts::read_list)

    if [[ ${#pending_labels[@]} -eq 0 ]]; then
        log::ok "All fonts already installed"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select fonts to install:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display font_archive count=0
    while IFS= read -r display; do
        font_archive="${archive_map[$display]}"
        _nerdfonts::download_font "$font_archive" "$display"
        _nerdfonts::is_font_installed "$font_archive" && count=$((count + 1))
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::info "Updating font cache"
        fc-cache -f 2>/dev/null || true
        log::ok "${count} font(s) installed"
    fi
}

# ── Select remove ───────────────────────────────────────

_nerdfonts::select_remove() {
    local archive label
    local installed_labels=()
    local -A archive_map=()

    while IFS='|' read -r archive label; do
        if _nerdfonts::is_font_installed "$archive"; then
            local display="${label} (${archive})"
            installed_labels+=("$display")
            archive_map["$display"]="$archive"
        fi
    done < <(_nerdfonts::read_list)

    if [[ ${#installed_labels[@]} -eq 0 ]]; then
        log::ok "No fonts installed"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select fonts to remove:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${installed_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display font_archive count=0
    while IFS= read -r display; do
        font_archive="${archive_map[$display]}"
        _nerdfonts::remove_font "$font_archive" "$display"
        count=$((count + 1))
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::info "Updating font cache"
        fc-cache -f 2>/dev/null || true
        log::ok "${count} font(s) removed"
    fi
}

# ── Download ────────────────────────────────────────────

_nerdfonts::download_font() {
    local archive="$1" label="$2"
    local url="${_NERDFONTS_BASE_URL}/${archive}.tar.xz"
    local target_dir="${_NERDFONTS_DIR}/${archive}"

    log::info "Downloading ${label}"

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! curl -fsSL "$url" -o "${tmpdir}/${archive}.tar.xz"; then
        log::error "Failed to download ${label}"
        rm -rf "$tmpdir"
        return
    fi

    mkdir -p "$target_dir"

    if ! tar -xJf "${tmpdir}/${archive}.tar.xz" -C "$target_dir"; then
        log::error "Failed to extract ${label}"
        rm -rf "$tmpdir" "$target_dir"
        return
    fi

    rm -rf "$tmpdir"
    log::ok "${label} installed"
}

# ── Remove ──────────────────────────────────────────────

_nerdfonts::remove_font() {
    local archive="$1" label="$2"
    local target_dir="${_NERDFONTS_DIR}/${archive}"

    if [[ -d "$target_dir" ]]; then
        rm -rf "$target_dir"
        log::ok "${label} removed"
    else
        log::warn "${label} not found"
    fi
}
