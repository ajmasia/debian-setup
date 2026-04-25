# Papirus Icons + Catppuccin folders task

[[ -n "${_MOD_ICONS_LOADED:-}" ]] && return 0
_MOD_ICONS_LOADED=1

_ICONS_LABEL="Configure Icons"
_ICONS_DESC="Install Papirus icons with Catppuccin folder colors."

_ICONS_PAPIRUS_FOLDERS_REPO="https://github.com/catppuccin/papirus-folders.git"
_ICONS_FOLDERS_SCRIPT="https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders"

_icons::is_installed() {
    local current
    current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
    [[ "$current" == "'Papirus-Dark'" ]] \
        || [[ "$current" == "'Papirus-Adwaita'" ]] \
        || [[ "$current" == "'Papirus-Dark-Adwaita'" ]]
}

_icons::active_variant() {
    local current
    current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
    case "$current" in
        "'Papirus-Dark'")          echo "catppuccin" ;;
        "'Papirus-Adwaita'")       echo "adwaita" ;;
        "'Papirus-Dark-Adwaita'")  echo "adwaita-dark" ;;
        *)                         echo "none" ;;
    esac
}

icons::check() {
    _icons::is_installed
}

icons::status() {
    _icons::is_installed || printf 'not installed'
}

icons::apply() {
    local choice

    while true; do
        local variant
        variant="$(_icons::active_variant)"

        ui::clear_content
        log::nav "GNOME > Appearance > Icons"
        log::break

        log::info "Papirus Icons"

        case "$variant" in
            "catppuccin")   log::ok "Icon theme: Papirus-Dark with Catppuccin folders" ;;
            "adwaita")      log::ok "Icon theme: Papirus with Adwaita folders" ;;
            "adwaita-dark") log::ok "Icon theme: Papirus-Dark with Adwaita folders" ;;
            *)
                local current
                current="$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null || true)"
                log::warn "Icon theme: ${current}"
                ;;
        esac

        log::break

        local options=()

        case "$variant" in
            "catppuccin")
                options+=("Change Folder Color" "Revert Icons")
                ;;
            "adwaita"|"adwaita-dark")
                options+=("Revert Icons")
                ;;
            *)
                options+=("Install Papirus" "Install Papirus + Catppuccin" \
                    "Install Papirus + Adwaita Folders" "Install Papirus-Dark + Adwaita Folders")
                ;;
        esac

        options+=("Back" "Exit")

        if [[ "${#options[@]}" -ge 5 ]]; then
            choice="$(gum::filter \
                --header "Select a change to apply:" \
                --header.foreground "$HEX_LAVENDER" \
                --indicator.foreground "$HEX_BLUE" \
                --text.foreground "$HEX_TEXT" \
                --match.foreground "$HEX_MAUVE" \
                --cursor-text.foreground "$HEX_GREEN" \
                "${options[@]}")"
        else
            choice="$(gum::choose \
                --header "Select a change to apply:" \
                --header.foreground "$HEX_LAVENDER" \
                --cursor.foreground "$HEX_BLUE" \
                --item.foreground "$HEX_TEXT" \
                --selected.foreground "$HEX_GREEN" \
                "${options[@]}")"
        fi

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            "Install Papirus")
                log::break
                _icons::install_base
                ui::return_or_exit
                ;;
            "Install Papirus + Catppuccin")
                log::break
                _icons::install
                ;;
            "Install Papirus + Adwaita Folders")
                log::break
                _icons::install_adwaita_folders "Papirus"
                ;;
            "Install Papirus-Dark + Adwaita Folders")
                log::break
                _icons::install_adwaita_folders "Papirus-Dark"
                ;;
            "Change Folder Color")
                log::break
                _icons::change_color
                ;;
            "Revert Icons")
                log::break
                _icons::revert
                ;;
        esac
    done
}

_icons::install_base() {
    # Install or reinstall papirus (reinstall cleans Catppuccin folder overrides)
    if dpkg -l papirus-icon-theme 2>/dev/null | grep -q '^ii'; then
        log::info "Reinstalling Papirus icon theme (clean state)"
        ui::flush_input
        if ! sudo apt-get install -y --reinstall papirus-icon-theme </dev/tty; then
            log::error "Failed to reinstall Papirus"
            return 1
        fi
        log::ok "Papirus reinstalled"
    else
        log::info "Installing Papirus icon theme"
        ui::flush_input
        if ! sudo apt-get install -y papirus-icon-theme </dev/tty; then
            log::error "Failed to install Papirus"
            return 1
        fi
        hash -r
        log::ok "Papirus installed"
    fi

    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark" || true
    log::ok "Papirus-Dark icon theme applied"
}

_icons::install() {
    if ! _icons::install_base; then
        ui::return_or_exit
        return
    fi

    # Choose accent
    local accent
    accent="$(gum::choose \
        --header "Select accent color for folder icons:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "lavender" "blue" "mauve" "pink" "rosewater" "flamingo" \
        "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire")"

    if [[ -z "$accent" ]]; then
        return
    fi

    # Clone Catppuccin folder assets
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Downloading Catppuccin folder icons"
    if ! git clone --depth 1 "$_ICONS_PAPIRUS_FOLDERS_REPO" "$tmpdir/papirus-folders" 2>/dev/null; then
        log::error "Failed to clone repository"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi

    log::info "Applying Catppuccin folder colors"
    ui::flush_input
    sudo cp -r "$tmpdir/papirus-folders/src/"* /usr/share/icons/Papirus/ </dev/tty

    # Download and run papirus-folders script
    if ! curl -fsSL "$_ICONS_FOLDERS_SCRIPT" -o "$tmpdir/papirus-folders-bin"; then
        log::error "Failed to download papirus-folders script"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi
    chmod +x "$tmpdir/papirus-folders-bin"

    if sudo "$tmpdir/papirus-folders-bin" -C "cat-mocha-${accent}" --theme Papirus-Dark </dev/tty; then
        log::ok "Folder colors applied: cat-mocha-${accent}"
    else
        log::warn "Failed to apply folder colors"
    fi

    rm -rf "$tmpdir"
    ui::return_or_exit
}

_icons::change_color() {
    local accent
    accent="$(gum::choose \
        --header "Select accent color for folder icons:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "lavender" "blue" "mauve" "pink" "rosewater" "flamingo" \
        "red" "maroon" "peach" "yellow" "green" "teal" "sky" "sapphire")"

    if [[ -z "$accent" ]]; then
        return
    fi

    local tmpdir
    tmpdir="$(mktemp -d)"

    if ! curl -fsSL "$_ICONS_FOLDERS_SCRIPT" -o "$tmpdir/papirus-folders-bin"; then
        log::error "Failed to download papirus-folders script"
        rm -rf "$tmpdir"
        ui::return_or_exit
        return
    fi
    chmod +x "$tmpdir/papirus-folders-bin"

    ui::flush_input
    if sudo "$tmpdir/papirus-folders-bin" -C "cat-mocha-${accent}" --theme Papirus-Dark </dev/tty; then
        log::ok "Folder color changed: cat-mocha-${accent}"
    else
        log::error "Failed to apply folder colors"
    fi

    rm -rf "$tmpdir"
    ui::return_or_exit
}

_icons::install_adwaita_folders() {
    local base="${1:-Papirus}"  # Papirus or Papirus-Dark
    local theme_name="${base}-Adwaita"

    # Ensure Papirus is installed
    if ! dpkg -l papirus-icon-theme 2>/dev/null | grep -q '^ii'; then
        log::info "Installing Papirus icon theme"
        ui::flush_input
        if ! sudo apt-get install -y papirus-icon-theme </dev/tty; then
            log::error "Failed to install Papirus"
            ui::return_or_exit
            return 1
        fi
        hash -r
        log::ok "Papirus installed"
    fi

    local adwaita="/usr/share/icons/Adwaita"
    if [[ ! -d "$adwaita" ]]; then
        log::error "Adwaita icons not found at $adwaita"
        ui::return_or_exit
        return 1
    fi

    local theme_dir="$HOME/.local/share/icons/${theme_name}"
    log::info "Creating ${theme_name} theme"
    mkdir -p "$theme_dir/16x16" "$theme_dir/scalable" "$theme_dir/symbolic"

    local dir
    for dir in 16x16/places scalable/places symbolic/places; do
        local src="$adwaita/$dir"
        local dst="$theme_dir/$dir"
        if [[ -d "$src" ]]; then
            rm -rf "$dst"
            ln -sf "$src" "$dst"
            log::ok "Linked $dir"
        else
            log::warn "Not found: $src (skipped)"
        fi
    done

    cat > "$theme_dir/index.theme" << EOF
[Icon Theme]
Name=${theme_name}
Comment=${base} icons with original Adwaita folders
Inherits=${base},Adwaita,hicolor

Directories=16x16/places,scalable/places,symbolic/places

[16x16/places]
Size=16
Type=Fixed
Context=Places

[scalable/places]
Size=48
MinSize=8
MaxSize=512
Type=Scalable
Context=Places

[symbolic/places]
Size=16
MinSize=8
MaxSize=512
Type=Scalable
Context=Places
EOF

    gtk-update-icon-cache "$theme_dir" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "${theme_name}" || true
    log::ok "${theme_name} icon theme applied"
    ui::return_or_exit
}

_icons::revert() {
    log::info "Reverting icon theme to default"
    gsettings reset org.gnome.desktop.interface icon-theme 2>/dev/null || true
    log::ok "Icon theme reverted"
    ui::return_or_exit
}
