# Terminal CSS padding task (GTK3 + GTK4)

[[ -n "${_MOD_TERMCSS_LOADED:-}" ]] && return 0
_MOD_TERMCSS_LOADED=1

_TERMCSS_LABEL="Configure Terminal CSS"
_TERMCSS_DESC="Add VTE terminal padding to GTK3 and GTK4 CSS."

_TERMCSS_GTK3_FILE="$HOME/.config/gtk-3.0/gtk.css"
_TERMCSS_GTK4_FILE="$HOME/.config/gtk-4.0/gtk.css"

_TERMCSS_MARKER="/* debian-setup: vte padding */"
_TERMCSS_SNIPPET="${_TERMCSS_MARKER}
VteTerminal,
TerminalScreen,
vte-terminal {
    padding: 12px;
    -VteTerminal-inner-border: 12px;
}"

# ── Checks ──────────────────────────────────────────────

_termcss::has_snippet() {
    local file="$1"
    [[ -f "$file" ]] && grep -qF 'debian-setup: vte padding' "$file"
}

termcss::check() {
    _termcss::has_snippet "$_TERMCSS_GTK3_FILE" && \
    _termcss::has_snippet "$_TERMCSS_GTK4_FILE"
}

termcss::status() {
    local missing=()
    _termcss::has_snippet "$_TERMCSS_GTK3_FILE" || missing+=("gtk-3.0")
    _termcss::has_snippet "$_TERMCSS_GTK4_FILE" || missing+=("gtk-4.0")
    if [[ ${#missing[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s missing' "${missing[*]}"
    fi
}

# ── Wizard ──────────────────────────────────────────────

termcss::apply() {
    local choice

    while true; do
        local gtk3_ok=false gtk4_ok=false
        _termcss::has_snippet "$_TERMCSS_GTK3_FILE" && gtk3_ok=true
        _termcss::has_snippet "$_TERMCSS_GTK4_FILE" && gtk4_ok=true

        ui::clear_content
        log::nav "GNOME > Terminal CSS"
        log::break

        log::info "VTE Terminal Padding (GTK3 + GTK4)"

        if $gtk3_ok; then
            log::ok "gtk-3.0/gtk.css: applied"
        else
            log::warn "gtk-3.0/gtk.css: not applied"
        fi

        if $gtk4_ok; then
            log::ok "gtk-4.0/gtk.css: applied"
        else
            log::warn "gtk-4.0/gtk.css: not applied"
        fi

        log::break

        local options=()

        if ! $gtk3_ok || ! $gtk4_ok; then
            options+=("Apply Terminal Padding")
        fi

        if $gtk3_ok || $gtk4_ok; then
            options+=("Remove Terminal Padding")
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
            "Apply Terminal Padding")
                log::break
                _termcss::apply_all
                ;;
            "Remove Terminal Padding")
                log::break
                _termcss::remove_all
                ;;
        esac
    done
}

# ── Apply ───────────────────────────────────────────────

_termcss::apply_to_file() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"

    mkdir -p "$dir"

    # If file is a symlink, resolve to regular file preserving content
    if [[ -L "$file" ]]; then
        local content
        content="$(cat "$file" 2>/dev/null || true)"
        rm "$file"
        printf '%s\n' "$content" > "$file"
    fi

    [[ -f "$file" ]] || touch "$file"

    if ! grep -qF 'debian-setup: vte padding' "$file"; then
        printf '\n%s\n' "$_TERMCSS_SNIPPET" >> "$file"
    fi
}

_termcss::apply_all() {
    log::info "Applying VTE terminal padding"

    _termcss::apply_to_file "$_TERMCSS_GTK3_FILE"
    log::ok "gtk-3.0/gtk.css updated"

    _termcss::apply_to_file "$_TERMCSS_GTK4_FILE"
    log::ok "gtk-4.0/gtk.css updated"
}

# ── Remove ──────────────────────────────────────────────

_termcss::remove_from_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    if grep -qF 'debian-setup: vte padding' "$file"; then
        sed -i '/debian-setup: vte padding/,/^}/d' "$file"
        # Clean trailing blank lines
        sed -i -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$file"
    fi
}

_termcss::remove_all() {
    log::info "Removing VTE terminal padding"

    _termcss::remove_from_file "$_TERMCSS_GTK3_FILE"
    log::ok "gtk-3.0/gtk.css cleaned"

    _termcss::remove_from_file "$_TERMCSS_GTK4_FILE"
    log::ok "gtk-4.0/gtk.css cleaned"
}
