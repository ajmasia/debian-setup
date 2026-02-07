# Catppuccin GTK Theme task

[[ -n "${_MOD_GTKTHEME_LOADED:-}" ]] && return 0
_MOD_GTKTHEME_LOADED=1

_GTKTHEME_LABEL="Configure GTK Theme"
_GTKTHEME_DESC="Install Catppuccin Mocha GTK theme."

_GTKTHEME_REPO="https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git"
_GTKTHEME_THEMES_DIR="$HOME/.themes"
_GTKTHEME_GTK4_DIR="$HOME/.config/gtk-4.0"
_GTKTHEME_DEPS=(git sassc gtk2-engines-murrine gnome-themes-extra gnome-shell-extension-user-theme)

_gtktheme::is_installed() {
    local current
    current="$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null || true)"
    [[ "$current" == *"Catppuccin"* ]]
}

_gtktheme::dark_mode_enabled() {
    local scheme
    scheme="$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || true)"
    [[ "$scheme" == "'prefer-dark'" ]]
}

_gtktheme::find_theme() {
    local name
    name="$(find "$_GTKTHEME_THEMES_DIR" -maxdepth 1 -type d -name "Catppuccin*" \
        -printf '%f\n' 2>/dev/null | head -1 || true)"
    printf '%s' "$name"
}

gtktheme::check() {
    _gtktheme::is_installed && _gtktheme::dark_mode_enabled
}

gtktheme::status() {
    local issues=()
    _gtktheme::dark_mode_enabled || issues+=("light mode")
    _gtktheme::is_installed || issues+=("not installed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

gtktheme::apply() {
    local choice

    while true; do
        local installed=false dark=false theme_name=""
        _gtktheme::is_installed && installed=true
        _gtktheme::dark_mode_enabled && dark=true
        theme_name="$(_gtktheme::find_theme)"

        ui::clear_content
        log::nav "GNOME > Appearance > GTK Theme"
        log::break

        log::info "GTK Theme"

        if $dark; then
            log::ok "Dark mode: enabled"
        else
            log::warn "Dark mode: disabled"
        fi

        if $installed && [[ -n "$theme_name" ]]; then
            log::ok "GTK theme: ${theme_name}"
        elif [[ -n "$theme_name" ]]; then
            log::warn "Theme installed but not active: ${theme_name}"
        else
            log::warn "Catppuccin GTK theme (not installed)"
        fi

        log::break

        local options=()

        if ! $dark; then
            options+=("Enable Dark Mode")
        fi

        if [[ -z "$theme_name" ]]; then
            options+=("Install Catppuccin GTK Theme")
        else
            if ! $installed; then
                options+=("Apply Catppuccin GTK Theme")
            fi
            options+=("Remove Catppuccin GTK Theme")
        fi

        if $dark; then
            options+=("Disable Dark Mode")
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
            "Enable Dark Mode")
                log::break
                gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
                log::ok "Dark mode enabled"
                ;;
            "Disable Dark Mode")
                log::break
                gsettings set org.gnome.desktop.interface color-scheme 'default'
                log::ok "Dark mode disabled"
                ;;
            "Install Catppuccin GTK Theme")
                log::break
                _gtktheme::install
                ;;
            "Apply Catppuccin GTK Theme")
                log::break
                gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
                log::ok "GTK theme applied: ${theme_name}"
                ;;
            "Remove Catppuccin GTK Theme")
                log::break
                _gtktheme::remove "$theme_name"
                ;;
        esac
    done
}

_gtktheme::install() {
    # Check dependencies
    local missing=()
    local dep
    for dep in "${_GTKTHEME_DEPS[@]}"; do
        if ! dpkg -l "$dep" 2>/dev/null | grep -q '^ii'; then
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log::info "Installing dependencies: ${missing[*]}"
        ui::flush_input
        if ! sudo apt-get install -y "${missing[@]}" </dev/tty; then
            log::error "Failed to install dependencies"
            return
        fi
        hash -r
        log::ok "Dependencies installed"
    fi

    # Choose accent color
    log::break
    local accent
    accent="$(gum::choose \
        --header "Select accent color:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "lavender" "blue" "mauve" "pink" "rosewater" "flamingo" \
        "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire")"

    if [[ -z "$accent" ]]; then
        return
    fi

    log::ok "Accent: ${accent}"

    # Clone and install
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Cloning Catppuccin-GTK-Theme"
    if ! git clone --depth 1 "$_GTKTHEME_REPO" "$tmpdir/catppuccin-gtk" 2>/dev/null; then
        log::error "Failed to clone repository"
        rm -rf "$tmpdir"
        return
    fi

    # Find install.sh (may be in themes/ subdirectory)
    local install_script
    install_script="$(find "$tmpdir/catppuccin-gtk" -name "install.sh" -type f | head -1)"

    if [[ -z "$install_script" ]]; then
        log::error "install.sh not found in repository"
        rm -rf "$tmpdir"
        return
    fi

    local script_dir
    script_dir="$(dirname "$install_script")"

    log::info "Installing theme (accent: ${accent})"
    chmod +x "$install_script"
    if (cd "$script_dir" && bash ./install.sh -t "$accent" -c dark -s standard -l); then
        log::ok "GTK theme files installed"
    else
        log::error "Theme installation failed"
        rm -rf "$tmpdir"
        return
    fi

    rm -rf "$tmpdir"

    # Detect installed theme name
    local theme_name
    theme_name="$(_gtktheme::find_theme)"

    if [[ -z "$theme_name" ]]; then
        log::warn "Could not detect installed theme name"
        return
    fi

    # Setup GTK4/libadwaita (assets+dark as symlinks, gtk.css as copy for termcss compat)
    local theme_path="$_GTKTHEME_THEMES_DIR/$theme_name"
    if [[ -d "$theme_path/gtk-4.0" ]]; then
        log::info "Setting up GTK4/libadwaita"
        mkdir -p "$_GTKTHEME_GTK4_DIR"
        ln -sf "$theme_path/gtk-4.0/assets" "$_GTKTHEME_GTK4_DIR/assets"
        ln -sf "$theme_path/gtk-4.0/gtk-dark.css" "$_GTKTHEME_GTK4_DIR/gtk-dark.css"

        # Preserve terminal CSS snippet if present in existing gtk.css
        local termcss_snippet=""
        if [[ -f "$_GTKTHEME_GTK4_DIR/gtk.css" ]] || [[ -L "$_GTKTHEME_GTK4_DIR/gtk.css" ]]; then
            termcss_snippet="$(sed -n '/debian-setup: vte padding/,/^}/p' "$_GTKTHEME_GTK4_DIR/gtk.css" 2>/dev/null || true)"
            rm -f "$_GTKTHEME_GTK4_DIR/gtk.css"
        fi

        cp "$theme_path/gtk-4.0/gtk.css" "$_GTKTHEME_GTK4_DIR/gtk.css"

        # Re-append terminal CSS if it was present
        if [[ -n "$termcss_snippet" ]]; then
            printf '\n%s\n' "$termcss_snippet" >> "$_GTKTHEME_GTK4_DIR/gtk.css"
        fi

        log::ok "GTK4 theme applied"
    fi

    # Apply theme
    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name"
    log::ok "GTK theme applied: ${theme_name}"

    # Enable dark mode if not already
    if ! _gtktheme::dark_mode_enabled; then
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
        log::ok "Dark mode enabled"
    fi
}

_gtktheme::remove() {
    local theme_name="$1"

    log::info "Removing Catppuccin GTK theme"

    # Remove theme directory
    if [[ -d "$_GTKTHEME_THEMES_DIR/$theme_name" ]]; then
        rm -rf "$_GTKTHEME_THEMES_DIR/$theme_name"
        log::ok "Theme files removed"
    fi

    # Remove GTK4 files
    if [[ -L "$_GTKTHEME_GTK4_DIR/assets" ]]; then
        rm -f "$_GTKTHEME_GTK4_DIR/assets" "$_GTKTHEME_GTK4_DIR/gtk.css" "$_GTKTHEME_GTK4_DIR/gtk-dark.css"
        log::ok "GTK4 theme files removed"
    fi

    # Reset to default theme
    gsettings reset org.gnome.desktop.interface gtk-theme 2>/dev/null || true
    log::ok "GTK theme reverted to default"
}
