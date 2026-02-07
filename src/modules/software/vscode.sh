# VS Code software task

[[ -n "${_MOD_VSCODE_LOADED:-}" ]] && return 0
_MOD_VSCODE_LOADED=1

_VSCODE_LABEL="Configure Visual Studio Code"
_VSCODE_DESC="Install Visual Studio Code."
_VSCODE_DEB_URL="https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
_VSCODE_EXT_LIST="${SCRIPT_DIR}/packages/vscode/extensions.txt"

# --- Private detection functions ---

_vscode::is_installed() {
    dpkg -l code 2>/dev/null | grep -q '^ii'
}

_vscode::session_ready() {
    command -v code &>/dev/null
}

_vscode::read_ext_list() {
    grep -v '^\s*#' "$_VSCODE_EXT_LIST" | grep -v '^\s*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

_vscode::ext_installed() {
    local ext_id="$1"
    code --list-extensions 2>/dev/null | grep -qiF "$ext_id"
}

# --- Public API ---

vscode::check() {
    _vscode::is_installed && _vscode::session_ready
}

vscode::status() {
    local issues=()
    _vscode::is_installed || issues+=("not installed")
    _vscode::is_installed && ! _vscode::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

vscode::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _vscode::is_installed && installed=true
        _vscode::session_ready && session_ready=true

        ui::clear_content
        log::nav "Software > Editors > VS Code"
        log::break

        log::info "Visual Studio Code"

        if $installed; then
            if $session_ready; then
                local version
                version="$(code --version 2>/dev/null | head -1 || true)"
                log::ok "VS Code: ${version}"
            else
                log::ok "VS Code: installed"
                log::warn "Restart needed to activate code in current session"
            fi
        else
            log::warn "VS Code (not installed)"
        fi

        # Show extension summary if code is usable
        if $installed && $session_ready; then
            local ext_total=0 ext_installed=0 line ext_id ext_label
            while IFS='|' read -r ext_id ext_label; do
                ext_total=$((ext_total + 1))
                _vscode::ext_installed "$ext_id" && ext_installed=$((ext_installed + 1))
            done < <(_vscode::read_ext_list)

            if [[ $ext_installed -eq $ext_total ]]; then
                log::ok "Extensions: ${ext_installed}/${ext_total} configured"
            else
                log::warn "Extensions: ${ext_installed}/${ext_total} configured"
            fi
        fi

        log::break

        local options=()

        if $installed; then
            if $session_ready; then
                options+=("Configure Extensions")
            fi
            options+=("Remove VS Code")
        else
            options+=("Install VS Code")
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
            "Install VS Code")
                log::break
                _vscode::install
                ;;
            "Configure Extensions")
                _vscode::ext_wizard
                ;;
            "Remove VS Code")
                log::break
                _vscode::remove
                ;;
        esac
    done
}

# --- Install VS Code ---

_vscode::install() {
    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    log::info "Downloading Visual Studio Code"
    if ! wget -qO "$tmpfile" "$_VSCODE_DEB_URL"; then
        log::error "Failed to download VS Code"
        rm -f "$tmpfile"
        ui::return_or_exit
        return
    fi
    log::ok "Download complete"

    log::info "Installing Visual Studio Code"
    log::break
    ui::flush_input
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        hash -r
        log::break
        log::ok "VS Code installed"
        log::break
        log::warn "The Microsoft repository has been added for automatic updates"
    else
        log::break
        log::error "Failed to install VS Code"
        ui::return_or_exit
    fi
    rm -f "$tmpfile"
}

# --- Remove VS Code ---

_vscode::remove() {
    log::info "Removing Visual Studio Code"
    ui::flush_input
    if sudo apt-get remove -y code </dev/tty; then
        hash -r
        log::ok "VS Code removed"
    else
        log::error "Failed to remove VS Code"
        return
    fi

    # Clean Microsoft repository and GPG key
    if [[ -f /etc/apt/sources.list.d/vscode.list ]]; then
        sudo rm -f /etc/apt/sources.list.d/vscode.list
        log::ok "Microsoft repository removed"
    fi
    if [[ -f /etc/apt/keyrings/packages.microsoft.gpg ]]; then
        sudo rm -f /etc/apt/keyrings/packages.microsoft.gpg
        log::ok "Microsoft GPG key removed"
    fi
}

# --- Extensions wizard ---

_vscode::ext_wizard() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Software > Editors > VS Code > Extensions"
        log::break

        log::info "VS Code Extensions"

        local line ext_id ext_label
        local all_installed=true has_installed=false
        while IFS='|' read -r ext_id ext_label; do
            if _vscode::ext_installed "$ext_id"; then
                log::ok "${ext_label} (${ext_id})"
                has_installed=true
            else
                log::warn "${ext_label} (${ext_id}) — not installed"
                all_installed=false
            fi
        done < <(_vscode::read_ext_list)

        log::break

        local options=()

        if ! $all_installed; then
            options+=("Install all pending" "Select extensions to install")
        fi

        if $has_installed; then
            options+=("Remove extensions")
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
            "Install all pending")
                log::break
                _vscode::ext_install_pending
                ;;
            "Select extensions to install")
                log::break
                _vscode::ext_select_install
                ;;
            "Remove extensions")
                log::break
                _vscode::ext_select_remove
                ;;
            "Edit extensions list")
                "${EDITOR:-vi}" "$_VSCODE_EXT_LIST" </dev/tty
                ;;
        esac
    done
}

_vscode::ext_install_pending() {
    local ext_id ext_label
    local count=0

    while IFS='|' read -r ext_id ext_label; do
        if ! _vscode::ext_installed "$ext_id"; then
            log::info "Installing ${ext_label}"
            if code --install-extension "$ext_id" --force 2>/dev/null; then
                log::ok "${ext_label} installed"
                count=$((count + 1))
            else
                log::error "Failed to install ${ext_label}"
            fi
        fi
    done < <(_vscode::read_ext_list)

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} extension(s) installed"
    fi
}

_vscode::ext_select_install() {
    local ext_id ext_label
    local pending_ids=() pending_labels=()
    local -A id_map=()

    while IFS='|' read -r ext_id ext_label; do
        if ! _vscode::ext_installed "$ext_id"; then
            local display="${ext_label} (${ext_id})"
            pending_labels+=("$display")
            id_map["$display"]="$ext_id"
        fi
    done < <(_vscode::read_ext_list)

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

    local display
    while IFS= read -r display; do
        ext_id="${id_map[$display]}"
        log::info "Installing ${display}"
        if code --install-extension "$ext_id" --force 2>/dev/null; then
            log::ok "Installed"
        else
            log::error "Failed to install ${ext_id}"
        fi
    done <<< "$selected"
}

_vscode::ext_select_remove() {
    local ext_id ext_label
    local installed_labels=()
    local -A id_map=()

    while IFS='|' read -r ext_id ext_label; do
        if _vscode::ext_installed "$ext_id"; then
            local display="${ext_label} (${ext_id})"
            installed_labels+=("$display")
            id_map["$display"]="$ext_id"
        fi
    done < <(_vscode::read_ext_list)

    if [[ ${#installed_labels[@]} -eq 0 ]]; then
        log::ok "No managed extensions installed"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select extensions to remove:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${installed_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local display
    while IFS= read -r display; do
        ext_id="${id_map[$display]}"
        log::info "Removing ${display}"
        if code --uninstall-extension "$ext_id" 2>/dev/null; then
            log::ok "Removed"
        else
            log::error "Failed to remove ${ext_id}"
        fi
    done <<< "$selected"
}
