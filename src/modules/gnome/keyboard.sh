# GNOME Keyboard layout, keybindings, and workspaces task

[[ -n "${_MOD_KEYBOARD_LOADED:-}" ]] && return 0
_MOD_KEYBOARD_LOADED=1

_KEYBOARD_LABEL="Configure Keyboard"
_KEYBOARD_DESC="Set keyboard layout, keybindings, and fixed workspaces."

_KEYBOARD_LAYOUT="us+altgr-intl"
_KEYBOARD_NUM_WORKSPACES=4
_KEYBOARD_TERMINAL_CMD="gnome-terminal"
_KEYBOARD_CUSTOM_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/debian-setup-terminal/"

# ── Checks ──────────────────────────────────────────────

_keyboard::layout_ok() {
    local sources
    sources="$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || true)"
    [[ "$sources" == *"'$_KEYBOARD_LAYOUT'"* ]]
}

_keyboard::workspaces_ok() {
    local dynamic num
    dynamic="$(gsettings get org.gnome.mutter dynamic-workspaces 2>/dev/null || true)"
    num="$(gsettings get org.gnome.desktop.wm.preferences num-workspaces 2>/dev/null || true)"
    [[ "$dynamic" == "false" ]] && [[ "$num" == "$_KEYBOARD_NUM_WORKSPACES" ]]
}

_keyboard::close_ok() {
    local val
    val="$(gsettings get org.gnome.desktop.wm.keybindings close 2>/dev/null || true)"
    [[ "$val" == *"'<Super>w'"* ]]
}

_keyboard::terminal_ok() {
    local binding
    binding="$(dconf read "${_KEYBOARD_CUSTOM_PATH}binding" 2>/dev/null || true)"
    [[ "$binding" == "'<Super>Return'" ]]
}

_keyboard::switch_ok() {
    local i val
    for i in 1 2 3 4; do
        val="$(gsettings get org.gnome.desktop.wm.keybindings switch-to-workspace-$i 2>/dev/null || true)"
        [[ "$val" == *"'<Super>$i'"* ]] || return 1
    done
}

_keyboard::move_ok() {
    local i val
    for i in 1 2 3 4; do
        val="$(gsettings get org.gnome.desktop.wm.keybindings move-to-workspace-$i 2>/dev/null || true)"
        [[ "$val" == *"'<Super><Shift>$i'"* ]] || return 1
    done
}

keyboard::check() {
    _keyboard::layout_ok && _keyboard::workspaces_ok && \
    _keyboard::close_ok && _keyboard::terminal_ok && \
    _keyboard::switch_ok && _keyboard::move_ok
}

keyboard::status() {
    local issues=()
    _keyboard::layout_ok || issues+=("layout")
    _keyboard::workspaces_ok || issues+=("workspaces")
    _keyboard::close_ok || issues+=("close binding")
    _keyboard::terminal_ok || issues+=("terminal binding")
    _keyboard::switch_ok || issues+=("switch bindings")
    _keyboard::move_ok || issues+=("move bindings")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

# ── Wizard ──────────────────────────────────────────────

keyboard::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "GNOME > Keyboard"
        log::break

        log::info "Layout, Keybindings & Workspaces"

        if _keyboard::layout_ok; then
            log::ok "Layout: English (intl, AltGr dead keys)"
        else
            log::warn "Layout: not configured"
        fi

        if _keyboard::workspaces_ok; then
            log::ok "Workspaces: ${_KEYBOARD_NUM_WORKSPACES} fixed"
        else
            log::warn "Workspaces: not configured"
        fi

        if _keyboard::close_ok; then
            log::ok "Close window: Super+W"
        else
            log::warn "Close window: not configured"
        fi

        if _keyboard::terminal_ok; then
            log::ok "Launch terminal: Super+Return"
        else
            log::warn "Launch terminal: not configured"
        fi

        if _keyboard::switch_ok; then
            log::ok "Switch workspace 1-4: Super+1..4"
        else
            log::warn "Switch workspace 1-4: not configured"
        fi

        if _keyboard::move_ok; then
            log::ok "Move to workspace 1-4: Super+Shift+1..4"
        else
            log::warn "Move to workspace 1-4: not configured"
        fi

        log::break

        local options=()
        local all_ok=true
        keyboard::check || all_ok=false

        if ! $all_ok; then
            options+=("Apply All Settings")
        fi

        local any_set=false
        _keyboard::layout_ok && any_set=true
        _keyboard::workspaces_ok && any_set=true
        _keyboard::close_ok && any_set=true
        _keyboard::terminal_ok && any_set=true
        _keyboard::switch_ok && any_set=true
        _keyboard::move_ok && any_set=true

        if $any_set; then
            options+=("Reset to Defaults")
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
            "Apply All Settings")
                log::break
                _keyboard::apply_all
                ;;
            "Reset to Defaults")
                log::break
                _keyboard::reset_all
                ;;
        esac
    done
}

# ── Apply ───────────────────────────────────────────────

_keyboard::apply_all() {
    # Layout
    log::info "Setting layout: English (intl, AltGr dead keys)"
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', '$_KEYBOARD_LAYOUT')]"
    log::ok "Layout configured"

    # Fixed workspaces
    log::info "Setting ${_KEYBOARD_NUM_WORKSPACES} fixed workspaces"
    gsettings set org.gnome.mutter dynamic-workspaces false
    gsettings set org.gnome.desktop.wm.preferences num-workspaces "$_KEYBOARD_NUM_WORKSPACES"
    log::ok "Workspaces configured"

    # Clear conflicting app-switcher bindings (Super+N defaults)
    log::info "Clearing conflicting app-switcher bindings"
    local i
    for i in 1 2 3 4 5 6 7 8 9; do
        gsettings set org.gnome.shell.keybindings switch-to-application-$i "[]"
    done
    log::ok "App-switcher bindings cleared"

    # Close window
    log::info "Setting keybinding: Super+W → Close window"
    gsettings set org.gnome.desktop.wm.keybindings close "['<Super>w']"
    log::ok "Close window binding set"

    # Switch workspace 1-4
    log::info "Setting keybindings: Super+1..4 → Switch workspace"
    for i in 1 2 3 4; do
        gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-$i "['<Super>$i']"
    done
    log::ok "Switch workspace bindings set"

    # Move to workspace 1-4
    log::info "Setting keybindings: Super+Shift+1..4 → Move to workspace"
    for i in 1 2 3 4; do
        gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-$i "['<Super><Shift>$i']"
    done
    log::ok "Move to workspace bindings set"

    # Custom: Super+Return → gnome-terminal
    log::info "Setting keybinding: Super+Return → gnome-terminal"
    _keyboard::apply_terminal_binding
    log::ok "Terminal binding set"
}

_keyboard::apply_terminal_binding() {
    dconf write "${_KEYBOARD_CUSTOM_PATH}name" "'Launch Terminal'"
    dconf write "${_KEYBOARD_CUSTOM_PATH}command" "'$_KEYBOARD_TERMINAL_CMD'"
    dconf write "${_KEYBOARD_CUSTOM_PATH}binding" "'<Super>Return'"

    # Add to custom keybindings list if not already there
    local current
    current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"

    if [[ "$current" != *"debian-setup-terminal"* ]]; then
        local our_path="'${_KEYBOARD_CUSTOM_PATH}'"
        if [[ "$current" == "@as []" || "$current" == "[]" ]]; then
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "[$our_path]"
        else
            local new_list="${current%]*}, $our_path]"
            gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"
        fi
    fi
}

# ── Reset ───────────────────────────────────────────────

_keyboard::reset_all() {
    log::info "Resetting keyboard settings to defaults"

    gsettings reset org.gnome.desktop.input-sources sources
    gsettings reset org.gnome.mutter dynamic-workspaces
    gsettings reset org.gnome.desktop.wm.preferences num-workspaces
    gsettings reset org.gnome.desktop.wm.keybindings close

    local i
    for i in 1 2 3 4; do
        gsettings reset org.gnome.desktop.wm.keybindings switch-to-workspace-$i
        gsettings reset org.gnome.desktop.wm.keybindings move-to-workspace-$i
    done

    # Restore app-switcher defaults
    for i in 1 2 3 4 5 6 7 8 9; do
        gsettings reset org.gnome.shell.keybindings switch-to-application-$i
    done

    _keyboard::remove_terminal_binding

    log::ok "All keyboard settings reset to defaults"
}

_keyboard::remove_terminal_binding() {
    dconf reset -f "$_KEYBOARD_CUSTOM_PATH"

    local current
    current="$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null || true)"

    if [[ "$current" == *"debian-setup-terminal"* ]]; then
        local our_path="'${_KEYBOARD_CUSTOM_PATH}'"
        local cleaned
        cleaned="$(printf '%s' "$current" | sed \
            -e "s|, *${our_path}||" \
            -e "s|${our_path}, *||" \
            -e "s|${our_path}||")"
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$cleaned"
    fi
}
