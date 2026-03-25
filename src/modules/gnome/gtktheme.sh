# Catppuccin GTK Theme task

[[ -n "${_MOD_GTKTHEME_LOADED:-}" ]] && return 0
_MOD_GTKTHEME_LOADED=1

_GTKTHEME_LABEL="Configure GTK Theme"
_GTKTHEME_DESC="Install Catppuccin GTK theme (Mocha or Latte)."

_GTKTHEME_REPO="https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme.git"
_GTKTHEME_THEMES_DIR="$HOME/.themes"
_GTKTHEME_GTK4_DIR="$HOME/.config/gtk-4.0"
_GTKTHEME_DEPS=(git sassc gtk2-engines-murrine gnome-themes-extra gnome-shell-extension-user-theme)
_GTKTHEME_ACCENTS=(lavender blue mauve pink rosewater flamingo red maroon peach yellow green teal sky sapphire)
_GTKTHEME_TWEAKS=(macos black float outline)

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
        ! -name "*-hdpi" ! -name "*-xhdpi" \
        -printf '%f\n' 2>/dev/null | head -1 || true)"
    printf '%s' "$name"
}

_gtktheme::current_variant() {
    local theme_name
    theme_name="$(_gtktheme::find_theme)"
    if [[ "$theme_name" == *"-Dark"* ]]; then
        printf 'dark'
    else
        printf 'light'
    fi
}

gtktheme::check() {
    _gtktheme::is_installed || return 1
    local variant
    variant="$(_gtktheme::current_variant)"
    if [[ "$variant" == "dark" ]]; then
        _gtktheme::dark_mode_enabled
    else
        ! _gtktheme::dark_mode_enabled
    fi
}

gtktheme::status() {
    local issues=()
    _gtktheme::is_installed || { printf 'not installed'; return; }
    local variant
    variant="$(_gtktheme::current_variant)"
    if [[ "$variant" == "dark" ]]; then
        _gtktheme::dark_mode_enabled || issues+=("light mode active")
    else
        _gtktheme::dark_mode_enabled && issues+=("dark mode active")
    fi
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

gtktheme::apply() {
    local choice

    while true; do
        local installed=false dark=false theme_name="" variant=""
        _gtktheme::is_installed && installed=true
        _gtktheme::dark_mode_enabled && dark=true
        theme_name="$(_gtktheme::find_theme)"
        [[ -n "$theme_name" ]] && variant="$(_gtktheme::current_variant)"

        ui::clear_content
        log::nav "GNOME > Appearance > GTK Theme"
        log::break

        log::info "GTK Theme"

        if [[ "$variant" == "light" ]]; then
            if $dark; then
                log::warn "Color scheme: dark (mismatched with Latte)"
            else
                log::ok "Color scheme: light"
            fi
        else
            if $dark; then
                log::ok "Color scheme: dark"
            else
                log::warn "Color scheme: light (mismatched with Mocha)"
            fi
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

        if [[ -z "$theme_name" ]]; then
            options+=("Install Catppuccin GTK Theme")
        else
            if ! $installed; then
                options+=("Apply Catppuccin GTK Theme")
            fi
            options+=("Change Accent" "Change Variant" "Change Tweaks")
            options+=("Remove Catppuccin GTK Theme")
        fi

        if ! $dark; then
            options+=("Enable Dark Mode")
        else
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
                gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
                log::ok "Dark mode enabled"
                ;;
            "Disable Dark Mode")
                log::break
                gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' || true
                log::ok "Dark mode disabled"
                ;;
            "Install Catppuccin GTK Theme")
                log::break
                _gtktheme::install
                ;;
            "Apply Catppuccin GTK Theme")
                log::break
                gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" || true
                log::ok "GTK theme applied: ${theme_name}"
                ;;
            "Change Accent")
                log::break
                _gtktheme::change_accent "$theme_name"
                ;;
            "Change Variant")
                log::break
                _gtktheme::change_variant "$theme_name"
                ;;
            "Change Tweaks")
                log::break
                _gtktheme::change_tweaks "$theme_name"
                ;;
            "Remove Catppuccin GTK Theme")
                log::break
                _gtktheme::remove "$theme_name"
                ;;
        esac
    done
}

# --- Helpers ---

_gtktheme::ensure_deps() {
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
            return 1
        fi
        hash -r
        log::ok "Dependencies installed"
    fi

    # Check User Themes extension
    local ut_uuid="user-theme@gnome-shell-extensions.gcampax.github.com"
    if ! gnome-extensions info "$ut_uuid" &>/dev/null; then
        log::warn "User Themes extension is not installed"
        log::warn "Install it from GNOME > Extensions or run:"
        log::warn "  sudo apt-get install gnome-shell-extension-user-theme"
        log::break

        local proceed
        proceed="$(gum::choose \
            --header "Continue without User Themes?" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Install extension now" "Continue anyway" "Cancel")"

        case "$proceed" in
            "Install extension now")
                ui::flush_input
                if sudo apt-get install -y gnome-shell-extension-user-theme </dev/tty; then
                    hash -r
                    log::ok "User Themes extension installed"
                    gnome-extensions enable "$ut_uuid" 2>/dev/null || true
                    log::warn "You may need to log out and back in to activate"
                else
                    log::error "Failed to install extension"
                    return 1
                fi
                ;;
            "Continue anyway")
                log::warn "Theme may not apply to GNOME Shell without User Themes"
                ;;
            *)
                return 1
                ;;
        esac
    elif ! gnome-extensions show "$ut_uuid" 2>/dev/null | grep -q "State: ACTIVE\|State: ENABLED"; then
        log::info "Enabling User Themes extension"
        gnome-extensions enable "$ut_uuid" 2>/dev/null || true
        log::ok "User Themes extension enabled"
    fi
}

_gtktheme::choose_variant() {
    gum::choose \
        --header "${1:-Select flavor:}" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "mocha (dark)" "latte (light)"
}

_gtktheme::choose_accent() {
    gum::choose \
        --header "${1:-Select accent color:}" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${_GTKTHEME_ACCENTS[@]}"
}

_gtktheme::choose_tweaks() {
    gum::choose \
        --header "Select tweaks (Space to mark, Enter to confirm):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        --no-limit \
        "macos (semaphore buttons)" "black (darker background)" \
        "float (floating panel)" "outline (2px window border)"
}

_gtktheme::clone_and_install() {
    local accent="$1"
    local variant="$2"   # "dark" (Mocha) or "light" (Latte)
    shift 2
    local tweaks=("$@")

    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Cloning Catppuccin-GTK-Theme"
    if ! git clone --depth 1 "$_GTKTHEME_REPO" "$tmpdir/catppuccin-gtk" 2>/dev/null; then
        log::error "Failed to clone repository"
        rm -rf "$tmpdir"
        return 1
    fi

    local install_script
    install_script="$(find "$tmpdir/catppuccin-gtk" -name "install.sh" -type f | head -1)"

    if [[ -z "$install_script" ]]; then
        log::error "install.sh not found in repository"
        rm -rf "$tmpdir"
        return 1
    fi

    local script_dir
    script_dir="$(dirname "$install_script")"
    chmod +x "$install_script"

    # Build install command (--tweaks must come before -t per upstream)
    local cmd=(bash ./install.sh)
    if [[ ${#tweaks[@]} -gt 0 && -n "${tweaks[0]}" ]]; then
        cmd+=(--tweaks "${tweaks[@]}")
    fi
    cmd+=(-t "$accent" -c "$variant" -s standard -l)

    log::info "Installing theme (flavor: ${variant}, accent: ${accent}${tweaks[*]:+, tweaks: ${tweaks[*]}})"
    if ! (cd "$script_dir" && "${cmd[@]}"); then
        log::error "Theme installation failed"
        rm -rf "$tmpdir"
        return 1
    fi

    rm -rf "$tmpdir"

    # Detect and setup
    local theme_name
    theme_name="$(_gtktheme::find_theme)"

    if [[ -z "$theme_name" ]]; then
        log::warn "Could not detect installed theme name"
        return 1
    fi

    _gtktheme::setup_gtk4 "$theme_name"

    gsettings set org.gnome.desktop.interface gtk-theme "$theme_name" || true
    log::ok "GTK theme applied: ${theme_name}"

    if [[ "$variant" == "dark" ]]; then
        if ! _gtktheme::dark_mode_enabled; then
            gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || true
            log::ok "Dark mode enabled"
        fi
    else
        if _gtktheme::dark_mode_enabled; then
            gsettings set org.gnome.desktop.interface color-scheme 'default' || true
            log::ok "Light mode enabled"
        fi
    fi
}

_gtktheme::setup_gtk4() {
    local theme_name="$1"
    local theme_path="$_GTKTHEME_THEMES_DIR/$theme_name"

    [[ -d "$theme_path/gtk-4.0" ]] || return 0

    log::info "Setting up GTK4/libadwaita"
    mkdir -p "$_GTKTHEME_GTK4_DIR"
    ln -sf "$theme_path/gtk-4.0/assets" "$_GTKTHEME_GTK4_DIR/assets"
    ln -sf "$theme_path/gtk-4.0/gtk-dark.css" "$_GTKTHEME_GTK4_DIR/gtk-dark.css"

    # Preserve terminal CSS snippet
    local termcss_snippet=""
    if [[ -f "$_GTKTHEME_GTK4_DIR/gtk.css" ]] || [[ -L "$_GTKTHEME_GTK4_DIR/gtk.css" ]]; then
        termcss_snippet="$(sed -n '/debian-setup: vte padding/,/^}/p' "$_GTKTHEME_GTK4_DIR/gtk.css" 2>/dev/null || true)"
        rm -f "$_GTKTHEME_GTK4_DIR/gtk.css"
    fi

    cp "$theme_path/gtk-4.0/gtk.css" "$_GTKTHEME_GTK4_DIR/gtk.css"

    if [[ -n "$termcss_snippet" ]]; then
        printf '\n%s\n' "$termcss_snippet" >> "$_GTKTHEME_GTK4_DIR/gtk.css"
    fi

    log::ok "GTK4 theme applied"
}

# --- Actions ---

_gtktheme::parse_tweaks() {
    # Extract tweak names from labels like "macos (semaphore buttons)"
    local line
    while IFS= read -r line; do
        [[ -n "$line" ]] && printf '%s\n' "${line%% *}"
    done
    return 0
}

_gtktheme::install() {
    _gtktheme::ensure_deps || return

    log::break
    local variant_choice variant
    variant_choice="$(_gtktheme::choose_variant)"
    [[ -z "$variant_choice" ]] && return
    # Map flavor name to install.sh -c flag value: mocha→dark, latte→light
    [[ "$variant_choice" == mocha* ]] && variant="dark" || variant="light"

    log::ok "Flavor: ${variant_choice}"
    log::break

    local accent
    accent="$(_gtktheme::choose_accent)"
    [[ -z "$accent" ]] && return

    log::ok "Accent: ${accent}"
    log::break

    local tweaks
    tweaks="$(_gtktheme::choose_tweaks | _gtktheme::parse_tweaks)"

    _gtktheme::clone_and_install "$accent" "$variant" $tweaks
}

_gtktheme::change_accent() {
    local old_theme="$1"
    local current_variant
    current_variant="$(_gtktheme::current_variant)"

    local accent
    accent="$(_gtktheme::choose_accent "Select new accent color:")"
    [[ -z "$accent" ]] && return

    rm -rf "$_GTKTHEME_THEMES_DIR/$old_theme"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-hdpi"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-xhdpi"
    _gtktheme::clone_and_install "$accent" "$current_variant"
}

_gtktheme::change_variant() {
    local old_theme="$1"

    local accent
    accent="$(printf '%s' "$old_theme" | sed 's/^Catppuccin-//; s/-Dark.*//; s/-Standard.*//; s/-Light.*//' | tr '[:upper:]' '[:lower:]')"
    [[ -z "$accent" ]] && accent="lavender"

    log::info "Current accent: ${accent}"
    log::break

    local variant_choice variant
    variant_choice="$(_gtktheme::choose_variant "Select new flavor:")"
    [[ -z "$variant_choice" ]] && return
    # Map flavor name to install.sh -c flag value: mocha→dark, latte→light
    [[ "$variant_choice" == mocha* ]] && variant="dark" || variant="light"

    rm -rf "$_GTKTHEME_THEMES_DIR/$old_theme"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-hdpi"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-xhdpi"
    _gtktheme::clone_and_install "$accent" "$variant"
}

_gtktheme::change_tweaks() {
    local old_theme="$1"
    local current_variant
    current_variant="$(_gtktheme::current_variant)"

    # Extract accent from theme name (e.g., "Catppuccin-Mauve-Dark" → "mauve")
    local accent
    accent="$(printf '%s' "$old_theme" | sed 's/^Catppuccin-//; s/-Dark.*//; s/-Standard.*//; s/-Light.*//' | tr '[:upper:]' '[:lower:]')"
    [[ -z "$accent" ]] && accent="lavender"

    log::info "Current accent: ${accent}, flavor: ${current_variant}"
    log::break

    local tweaks
    tweaks="$(_gtktheme::choose_tweaks | _gtktheme::parse_tweaks)"

    rm -rf "$_GTKTHEME_THEMES_DIR/$old_theme"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-hdpi"
    rm -rf "$_GTKTHEME_THEMES_DIR/${old_theme}-xhdpi"
    _gtktheme::clone_and_install "$accent" "$current_variant" $tweaks
}

_gtktheme::remove() {
    local theme_name="$1"

    log::info "Removing Catppuccin GTK theme"

    if [[ -d "$_GTKTHEME_THEMES_DIR/$theme_name" ]]; then
        rm -rf "$_GTKTHEME_THEMES_DIR/$theme_name"
        rm -rf "$_GTKTHEME_THEMES_DIR/${theme_name}-hdpi"
        rm -rf "$_GTKTHEME_THEMES_DIR/${theme_name}-xhdpi"
        log::ok "Theme files removed"
    fi

    if [[ -L "$_GTKTHEME_GTK4_DIR/assets" ]]; then
        rm -f "$_GTKTHEME_GTK4_DIR/assets" "$_GTKTHEME_GTK4_DIR/gtk.css" "$_GTKTHEME_GTK4_DIR/gtk-dark.css"
        log::ok "GTK4 theme files removed"
    fi

    gsettings reset org.gnome.desktop.interface gtk-theme 2>/dev/null || true
    log::ok "GTK theme reverted to default"
}

_gtktheme::reset_native() {
    local theme_name
    theme_name="$(_gtktheme::find_theme)"

    log::info "The following changes will be applied:"
    log::warn "  - GTK theme reset to Adwaita"
    log::warn "  - Color scheme set to light (prefer-light)"
    log::warn "  - GNOME Shell theme reset to default"
    log::warn "  - Icon theme reset to default (Adwaita)"
    log::warn "  - Cursor theme reset to default"
    if [[ -n "$theme_name" ]]; then
        log::warn "  - Catppuccin theme files removed (~/.themes)"
    fi
    if [[ -L "$_GTKTHEME_GTK4_DIR/assets" || -f "$_GTKTHEME_GTK4_DIR/gtk.css" ]]; then
        log::warn "  - GTK4 CSS removed (including terminal padding)"
    fi
    log::break

    local confirm
    confirm="$(gum::choose \
        --header "Apply all changes and reset to native GNOME?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes, reset to native GNOME" "Cancel")"

    [[ "$confirm" != "Yes, reset to native GNOME" ]] && return 1

    log::break
    log::info "Resetting to native GNOME (Adwaita)"

    # Remove Catppuccin theme files if present
    if [[ -n "$theme_name" && -d "$_GTKTHEME_THEMES_DIR/$theme_name" ]]; then
        rm -rf "$_GTKTHEME_THEMES_DIR/$theme_name"
        rm -rf "$_GTKTHEME_THEMES_DIR/${theme_name}-hdpi"
        rm -rf "$_GTKTHEME_THEMES_DIR/${theme_name}-xhdpi"
        log::ok "Catppuccin theme files removed"
    fi

    # Remove GTK4 symlinks and CSS
    if [[ -L "$_GTKTHEME_GTK4_DIR/assets" || -f "$_GTKTHEME_GTK4_DIR/gtk.css" ]]; then
        rm -f "$_GTKTHEME_GTK4_DIR/assets" \
              "$_GTKTHEME_GTK4_DIR/gtk.css" \
              "$_GTKTHEME_GTK4_DIR/gtk-dark.css"
        log::ok "GTK4 customizations removed"
    fi

    # Reset GTK theme to Adwaita
    gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita' 2>/dev/null || true
    log::ok "GTK theme set to Adwaita"

    # Reset color scheme to light (GNOME 48 requires prefer-light, not default)
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-light' 2>/dev/null || true
    log::ok "Color scheme set to light"

    # Reset GNOME Shell theme (User Themes extension)
    gsettings set org.gnome.shell.extensions.user-theme name '' 2>/dev/null || true
    log::ok "GNOME Shell theme reset to default"

    # Reset icon theme
    gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
    log::ok "Icon theme reset to default"

    # Reset cursor theme
    gsettings reset org.gnome.desktop.interface cursor-theme 2>/dev/null || true
    log::ok "Cursor theme reset to default"

    log::break
    log::warn "GNOME Shell requires a restart to apply the theme change"
    log::warn "  Press Alt+F2, type 'r', press Enter  (X11 only)"
    log::warn "  Or log out and back in (works on X11 and Wayland)"
    log::info "Note: the quick settings panel stays dark by design (Adwaita shell theme)"
    ui::return_or_exit
}
