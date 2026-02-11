# App themes — Catppuccin Mocha for CLI apps

[[ -n "${_MOD_APPTHEMES_LOADED:-}" ]] && return 0
_MOD_APPTHEMES_LOADED=1

_APPTHEMES_LABEL="App Themes"
_APPTHEMES_DESC="Catppuccin Mocha themes for CLI apps (btop, Alacritty, Atuin, bat, cava, eza, lazygit, Starship)."

_APPTHEMES_MARKER_START="# debian-setup: catppuccin-mocha start"
_APPTHEMES_MARKER_END="# debian-setup: catppuccin-mocha end"

_APPTHEMES_ACCENTS=(
    "rosewater" "flamingo" "pink" "mauve" "red" "maroon"
    "peach" "yellow" "green" "teal" "sky" "sapphire" "blue" "lavender"
)

# ── Shared utilities ────────────────────────────────────────────────

_appthemes::has_marker() {
    local file="$1" marker="${2:-catppuccin-mocha}"
    [[ -f "$file" ]] && grep -Fq "# debian-setup: ${marker} start" "$file"
}

_appthemes::remove_marker_block() {
    local file="$1" marker="${2:-catppuccin-mocha}"
    [[ -f "$file" ]] || return 0
    local start_pat="# debian-setup: ${marker} start"
    local end_pat="# debian-setup: ${marker} end"
    local tmp
    tmp="$(mktemp)"
    awk -v s="$start_pat" -v e="$end_pat" '
        $0 == s { skip=1; next }
        $0 == e { skip=0; next }
        !skip { print }
    ' "$file" > "$tmp"
    mv "$tmp" "$file"
}

_appthemes::choose_accent() {
    local accent
    accent="$(gum::choose \
        --header "Select accent color:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${_APPTHEMES_ACCENTS[@]}")"
    printf '%s' "$accent"
}

_appthemes::ensure_config() {
    local file="$1"
    local dir
    dir="$(dirname "$file")"
    [[ -d "$dir" ]] || mkdir -p "$dir"
    [[ -f "$file" ]] || touch "$file"
}

# ── btop ────────────────────────────────────────────────────────────

_BTOP_LABEL="btop Theme"
_BTOP_DESC="Catppuccin Mocha theme for btop."
_BTOP_CONFIG_DIR="${HOME}/.config/btop"
_BTOP_THEME_DIR="${_BTOP_CONFIG_DIR}/themes"
_BTOP_THEME_FILE="${_BTOP_THEME_DIR}/catppuccin_mocha.theme"
_BTOP_CONFIG="${_BTOP_CONFIG_DIR}/btop.conf"
_BTOP_URL="https://raw.githubusercontent.com/catppuccin/btop/main/themes/catppuccin_mocha.theme"

_appthemes::btop_installed() {
    [[ -f "$_BTOP_THEME_FILE" ]] && _appthemes::has_marker "$_BTOP_CONFIG"
}

_appthemes::btop_install() {
    log::info "Installing btop Catppuccin Mocha theme"
    mkdir -p "$_BTOP_THEME_DIR"
    if ! curl -fsSL -o "$_BTOP_THEME_FILE" "$_BTOP_URL"; then
        log::error "Failed to download btop theme"
        return
    fi
    log::ok "Theme file downloaded"

    _appthemes::ensure_config "$_BTOP_CONFIG"
    _appthemes::remove_marker_block "$_BTOP_CONFIG"
    {
        printf '\n%s\n' "$_APPTHEMES_MARKER_START"
        printf 'color_theme = "catppuccin_mocha"\n'
        printf '%s\n' "$_APPTHEMES_MARKER_END"
    } >> "$_BTOP_CONFIG"
    log::ok "btop theme installed"
}

_appthemes::btop_remove() {
    log::info "Removing btop Catppuccin Mocha theme"
    rm -f "$_BTOP_THEME_FILE"
    _appthemes::remove_marker_block "$_BTOP_CONFIG"
    log::ok "btop theme removed"
}

_appthemes::btop_status() {
    local issues=()
    [[ -f "$_BTOP_THEME_FILE" ]] || issues+=("theme file missing")
    _appthemes::has_marker "$_BTOP_CONFIG" || issues+=("config missing")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

_appthemes::btop_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::btop_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > btop"
        log::break

        log::info "btop — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            local detail
            detail="$(_appthemes::btop_status)"
            log::warn "Theme: ${detail:-not installed}"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::btop_install ;;
            "Remove Theme") log::break; _appthemes::btop_remove ;;
        esac
    done
}

# ── Alacritty ───────────────────────────────────────────────────────

_ALACRITTY_LABEL="Alacritty Theme"
_ALACRITTY_DESC="Catppuccin Mocha theme for Alacritty."
_ALACRITTY_CONFIG_DIR="${HOME}/.config/alacritty"
_ALACRITTY_THEME_FILE="${_ALACRITTY_CONFIG_DIR}/catppuccin-mocha.toml"
_ALACRITTY_CONFIG="${_ALACRITTY_CONFIG_DIR}/alacritty.toml"
_ALACRITTY_URL="https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml"

_appthemes::alacritty_installed() {
    [[ -f "$_ALACRITTY_THEME_FILE" ]] && _appthemes::has_marker "$_ALACRITTY_CONFIG"
}

_appthemes::alacritty_install() {
    log::info "Installing Alacritty Catppuccin Mocha theme"
    mkdir -p "$_ALACRITTY_CONFIG_DIR"
    if ! curl -fsSL -o "$_ALACRITTY_THEME_FILE" "$_ALACRITTY_URL"; then
        log::error "Failed to download Alacritty theme"
        return
    fi
    log::ok "Theme file downloaded"

    _appthemes::ensure_config "$_ALACRITTY_CONFIG"
    if ! _appthemes::has_marker "$_ALACRITTY_CONFIG"; then
        {
            printf '\n%s\n' "$_APPTHEMES_MARKER_START"
            printf '[general]\nimport = ["~/.config/alacritty/catppuccin-mocha.toml"]\n'
            printf '%s\n' "$_APPTHEMES_MARKER_END"
        } >> "$_ALACRITTY_CONFIG"
        log::ok "Import added to alacritty.toml"
    fi
    log::ok "Alacritty theme installed"
}

_appthemes::alacritty_remove() {
    log::info "Removing Alacritty Catppuccin Mocha theme"
    rm -f "$_ALACRITTY_THEME_FILE"
    _appthemes::remove_marker_block "$_ALACRITTY_CONFIG"
    log::ok "Alacritty theme removed"
}

_appthemes::alacritty_status() {
    local issues=()
    [[ -f "$_ALACRITTY_THEME_FILE" ]] || issues+=("theme file missing")
    _appthemes::has_marker "$_ALACRITTY_CONFIG" || issues+=("import missing")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

_appthemes::alacritty_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::alacritty_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > Alacritty"
        log::break

        log::info "Alacritty — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            local detail
            detail="$(_appthemes::alacritty_status)"
            log::warn "Theme: ${detail:-not installed}"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::alacritty_install ;;
            "Remove Theme") log::break; _appthemes::alacritty_remove ;;
        esac
    done
}

# ── Atuin ───────────────────────────────────────────────────────────

_ATUIN_LABEL="Atuin Theme"
_ATUIN_DESC="Catppuccin Mocha theme for Atuin."
_ATUIN_CONFIG_DIR="${HOME}/.config/atuin"
_ATUIN_THEMES_DIR="${_ATUIN_CONFIG_DIR}/themes"
_ATUIN_CONFIG="${_ATUIN_CONFIG_DIR}/config.toml"
_ATUIN_URL_BASE="https://raw.githubusercontent.com/catppuccin/atuin/main/themes/mocha"

_appthemes::atuin_installed() {
    local f
    for f in "${_ATUIN_THEMES_DIR}"/catppuccin-mocha-*.toml; do
        [[ -f "$f" ]] && _appthemes::has_marker "$_ATUIN_CONFIG" && return 0
    done
    return 1
}

_appthemes::atuin_install() {
    local accent
    accent="$(_appthemes::choose_accent)"
    [[ -z "$accent" ]] && return

    log::info "Installing Atuin Catppuccin Mocha (${accent}) theme"
    mkdir -p "$_ATUIN_THEMES_DIR"

    local theme_file="${_ATUIN_THEMES_DIR}/catppuccin-mocha-${accent}.toml"
    if ! curl -fsSL -o "$theme_file" "${_ATUIN_URL_BASE}/catppuccin-mocha-${accent}.toml"; then
        log::error "Failed to download Atuin theme"
        return
    fi
    log::ok "Theme file downloaded"

    _appthemes::ensure_config "$_ATUIN_CONFIG"
    _appthemes::remove_marker_block "$_ATUIN_CONFIG"
    {
        printf '\n%s\n' "$_APPTHEMES_MARKER_START"
        printf '[theme]\n'
        printf 'name = "catppuccin-mocha-%s"\n' "$accent"
        printf '%s\n' "$_APPTHEMES_MARKER_END"
    } >> "$_ATUIN_CONFIG"
    log::ok "Atuin theme installed"
}

_appthemes::atuin_remove() {
    log::info "Removing Atuin Catppuccin Mocha theme"
    rm -f "${_ATUIN_THEMES_DIR}"/catppuccin-mocha-*.toml
    _appthemes::remove_marker_block "$_ATUIN_CONFIG"
    log::ok "Atuin theme removed"
}

_appthemes::atuin_status() {
    local issues=()
    local found=false
    local f
    for f in "${_ATUIN_THEMES_DIR}"/catppuccin-mocha-*.toml; do
        [[ -f "$f" ]] && found=true && break
    done
    $found || issues+=("theme file missing")
    _appthemes::has_marker "$_ATUIN_CONFIG" || issues+=("config missing")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

_appthemes::atuin_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::atuin_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > Atuin"
        log::break

        log::info "Atuin — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            local detail
            detail="$(_appthemes::atuin_status)"
            log::warn "Theme: ${detail:-not installed}"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::atuin_install ;;
            "Remove Theme") log::break; _appthemes::atuin_remove ;;
        esac
    done
}

# ── bat ─────────────────────────────────────────────────────────────

_BAT_LABEL="bat Theme"
_BAT_DESC="Catppuccin Mocha theme for bat."
_BAT_URL="https://raw.githubusercontent.com/catppuccin/bat/main/themes/Catppuccin%20Mocha.tmTheme"

_appthemes::bat_cmd() {
    if command -v batcat >/dev/null 2>&1; then
        printf 'batcat'
    elif command -v bat >/dev/null 2>&1; then
        printf 'bat'
    fi
}

_appthemes::bat_config_dir() {
    local cmd
    cmd="$(_appthemes::bat_cmd)"
    if [[ -n "$cmd" ]]; then
        "$cmd" --config-dir 2>/dev/null || printf '%s' "${HOME}/.config/bat"
    else
        printf '%s' "${HOME}/.config/bat"
    fi
}

_appthemes::bat_installed() {
    [[ -n "$(_appthemes::bat_cmd)" ]] || return 1
    local config_dir
    config_dir="$(_appthemes::bat_config_dir)"
    [[ -f "${config_dir}/themes/Catppuccin Mocha.tmTheme" ]]
}

_appthemes::bat_install() {
    local cmd
    cmd="$(_appthemes::bat_cmd)"
    if [[ -z "$cmd" ]]; then
        log::error "bat is not installed"
        return
    fi

    local config_dir
    config_dir="$(_appthemes::bat_config_dir)"

    log::info "Installing bat Catppuccin Mocha theme"
    mkdir -p "${config_dir}/themes"
    if ! curl -fsSL -o "${config_dir}/themes/Catppuccin Mocha.tmTheme" "$_BAT_URL"; then
        log::error "Failed to download bat theme"
        return
    fi
    log::ok "Theme file downloaded"

    "$cmd" cache --build >/dev/null 2>&1
    log::ok "bat cache rebuilt"

    local bat_config="${config_dir}/config"
    _appthemes::ensure_config "$bat_config"
    _appthemes::remove_marker_block "$bat_config"
    {
        printf '\n%s\n' "$_APPTHEMES_MARKER_START"
        printf '%s\n' '--theme="Catppuccin Mocha"'
        printf '%s\n' "$_APPTHEMES_MARKER_END"
    } >> "$bat_config"
    log::ok "bat theme installed"
}

_appthemes::bat_remove() {
    local cmd
    cmd="$(_appthemes::bat_cmd)"
    local config_dir
    config_dir="$(_appthemes::bat_config_dir)"

    log::info "Removing bat Catppuccin Mocha theme"
    rm -f "${config_dir}/themes/Catppuccin Mocha.tmTheme"

    if [[ -n "$cmd" ]]; then
        "$cmd" cache --build >/dev/null 2>&1
    fi

    local bat_config="${config_dir}/config"
    _appthemes::remove_marker_block "$bat_config"
    log::ok "bat theme removed"
}

_appthemes::bat_status() {
    [[ -n "$(_appthemes::bat_cmd)" ]] || { printf 'bat not installed'; return; }
    _appthemes::bat_installed || printf 'not installed'
}

_appthemes::bat_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::bat_installed && installed=true
        local bat_available=false
        [[ -n "$(_appthemes::bat_cmd)" ]] && bat_available=true

        ui::clear_content
        log::nav "UI > App Themes > bat"
        log::break

        log::info "bat — Catppuccin Mocha"

        if ! $bat_available; then
            log::warn "bat: not installed (install bat first)"
        elif $installed; then
            log::ok "Theme: installed"
        else
            log::warn "Theme: not installed"
        fi

        log::break

        local options=()
        if $bat_available; then
            if $installed; then
                options+=("Remove Theme")
            else
                options+=("Install Theme")
            fi
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::bat_install ;;
            "Remove Theme") log::break; _appthemes::bat_remove ;;
        esac
    done
}

# ── cava ────────────────────────────────────────────────────────────

_CAVA_LABEL="cava Theme"
_CAVA_DESC="Catppuccin Mocha theme for cava."
_CAVA_CONFIG="${HOME}/.config/cava/config"
_CAVA_URL="https://raw.githubusercontent.com/catppuccin/cava/main/themes/mocha.cava"

_appthemes::cava_installed() {
    _appthemes::has_marker "$_CAVA_CONFIG"
}

_appthemes::cava_install() {
    log::info "Installing cava Catppuccin Mocha theme"

    local theme_content
    if ! theme_content="$(curl -fsSL "$_CAVA_URL")"; then
        log::error "Failed to download cava theme"
        return
    fi

    _appthemes::ensure_config "$_CAVA_CONFIG"
    _appthemes::remove_marker_block "$_CAVA_CONFIG"
    {
        printf '\n%s\n' "$_APPTHEMES_MARKER_START"
        printf '%s\n' "$theme_content"
        printf '%s\n' "$_APPTHEMES_MARKER_END"
    } >> "$_CAVA_CONFIG"
    log::ok "cava theme installed"
}

_appthemes::cava_remove() {
    log::info "Removing cava Catppuccin Mocha theme"
    _appthemes::remove_marker_block "$_CAVA_CONFIG"
    log::ok "cava theme removed"
}

_appthemes::cava_status() {
    _appthemes::cava_installed || printf 'not installed'
}

_appthemes::cava_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::cava_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > cava"
        log::break

        log::info "cava — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            log::warn "Theme: not installed"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::cava_install ;;
            "Remove Theme") log::break; _appthemes::cava_remove ;;
        esac
    done
}

# ── eza ─────────────────────────────────────────────────────────────

_EZA_LABEL="eza Theme"
_EZA_DESC="Catppuccin Mocha theme for eza."
_EZA_CONFIG_DIR="${HOME}/.config/eza"
_EZA_THEME_FILE="${_EZA_CONFIG_DIR}/theme.yml"
_EZA_URL_BASE="https://raw.githubusercontent.com/catppuccin/eza/main/themes/mocha"

_appthemes::eza_installed() {
    [[ -f "$_EZA_THEME_FILE" ]]
}

_appthemes::eza_install() {
    local accent
    accent="$(_appthemes::choose_accent)"
    [[ -z "$accent" ]] && return

    log::info "Installing eza Catppuccin Mocha (${accent}) theme"
    mkdir -p "$_EZA_CONFIG_DIR"
    if curl -fsSL -o "$_EZA_THEME_FILE" "${_EZA_URL_BASE}/catppuccin-mocha-${accent}.yml"; then
        log::ok "eza theme installed"
    else
        log::error "Failed to download eza theme"
    fi
}

_appthemes::eza_remove() {
    log::info "Removing eza Catppuccin Mocha theme"
    rm -f "$_EZA_THEME_FILE"
    log::ok "eza theme removed"
}

_appthemes::eza_status() {
    _appthemes::eza_installed || printf 'not installed'
}

_appthemes::eza_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::eza_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > eza"
        log::break

        log::info "eza — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            log::warn "Theme: not installed"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::eza_install ;;
            "Remove Theme") log::break; _appthemes::eza_remove ;;
        esac
    done
}

# ── lazygit ─────────────────────────────────────────────────────────

_LAZYGIT_LABEL="lazygit Theme"
_LAZYGIT_DESC="Catppuccin Mocha theme for lazygit."
_LAZYGIT_CONFIG_DIR="${HOME}/.config/lazygit"
_LAZYGIT_CONFIG="${_LAZYGIT_CONFIG_DIR}/config.yml"
_LAZYGIT_URL_BASE="https://raw.githubusercontent.com/catppuccin/lazygit/main/themes/mocha"

_appthemes::lazygit_installed() {
    _appthemes::has_marker "$_LAZYGIT_CONFIG"
}

_appthemes::lazygit_install() {
    local accent
    accent="$(_appthemes::choose_accent)"
    [[ -z "$accent" ]] && return

    log::info "Installing lazygit Catppuccin Mocha (${accent}) theme"

    local theme_content
    if ! theme_content="$(curl -fsSL "${_LAZYGIT_URL_BASE}/${accent}.yml")"; then
        log::error "Failed to download lazygit theme"
        return
    fi

    _appthemes::ensure_config "$_LAZYGIT_CONFIG"
    _appthemes::remove_marker_block "$_LAZYGIT_CONFIG"
    {
        printf '\n%s\n' "$_APPTHEMES_MARKER_START"
        printf '%s\n' "$theme_content"
        printf '%s\n' "$_APPTHEMES_MARKER_END"
    } >> "$_LAZYGIT_CONFIG"
    log::ok "lazygit theme installed"
}

_appthemes::lazygit_remove() {
    log::info "Removing lazygit Catppuccin Mocha theme"
    _appthemes::remove_marker_block "$_LAZYGIT_CONFIG"
    log::ok "lazygit theme removed"
}

_appthemes::lazygit_status() {
    _appthemes::lazygit_installed || printf 'not installed'
}

_appthemes::lazygit_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::lazygit_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > lazygit"
        log::break

        log::info "lazygit — Catppuccin Mocha"

        if $installed; then
            log::ok "Theme: installed"
        else
            log::warn "Theme: not installed"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Theme")
        else
            options+=("Install Theme")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Theme") log::break; _appthemes::lazygit_install ;;
            "Remove Theme") log::break; _appthemes::lazygit_remove ;;
        esac
    done
}

# ── Starship ────────────────────────────────────────────────────────

_STARSHIP_LABEL="Starship Theme"
_STARSHIP_DESC="Catppuccin Mocha palette for Starship."
_STARSHIP_CONFIG="${HOME}/.config/starship.toml"
_STARSHIP_URL="https://raw.githubusercontent.com/catppuccin/starship/main/themes/mocha.toml"
_STARSHIP_PALETTE_MARKER="catppuccin-mocha-palette"
_STARSHIP_TABLE_MARKER="catppuccin-mocha"

_appthemes::starship_installed() {
    _appthemes::has_marker "$_STARSHIP_CONFIG" "$_STARSHIP_PALETTE_MARKER"
}

_appthemes::starship_install() {
    log::info "Installing Starship Catppuccin Mocha palette"

    local palette_table
    if ! palette_table="$(curl -fsSL "$_STARSHIP_URL")"; then
        log::error "Failed to download Starship palette"
        return
    fi

    _appthemes::ensure_config "$_STARSHIP_CONFIG"

    # Remove any previous blocks
    _appthemes::remove_marker_block "$_STARSHIP_CONFIG" "$_STARSHIP_PALETTE_MARKER"
    _appthemes::remove_marker_block "$_STARSHIP_CONFIG" "$_STARSHIP_TABLE_MARKER"

    # Prepend palette line at the top of the file
    local tmp
    tmp="$(mktemp)"
    {
        printf '%s\n' "# debian-setup: ${_STARSHIP_PALETTE_MARKER} start"
        printf 'palette = "catppuccin_mocha"\n'
        printf '%s\n' "# debian-setup: ${_STARSHIP_PALETTE_MARKER} end"
        printf '\n'
        cat "$_STARSHIP_CONFIG"
    } > "$tmp"
    mv "$tmp" "$_STARSHIP_CONFIG"
    log::ok "Palette line added"

    # Append palette table at the end
    {
        printf '\n%s\n' "# debian-setup: ${_STARSHIP_TABLE_MARKER} start"
        printf '%s\n' "$palette_table"
        printf '%s\n' "# debian-setup: ${_STARSHIP_TABLE_MARKER} end"
    } >> "$_STARSHIP_CONFIG"
    log::ok "Starship palette installed"
}

_appthemes::starship_remove() {
    log::info "Removing Starship Catppuccin Mocha palette"
    _appthemes::remove_marker_block "$_STARSHIP_CONFIG" "$_STARSHIP_PALETTE_MARKER"
    _appthemes::remove_marker_block "$_STARSHIP_CONFIG" "$_STARSHIP_TABLE_MARKER"
    log::ok "Starship palette removed"
}

_appthemes::starship_status() {
    _appthemes::starship_installed || printf 'not installed'
}

_appthemes::starship_apply() {
    local choice

    while true; do
        local installed=false
        _appthemes::starship_installed && installed=true

        ui::clear_content
        log::nav "UI > App Themes > Starship"
        log::break

        log::info "Starship — Catppuccin Mocha"

        if $installed; then
            log::ok "Palette: installed"
        else
            log::warn "Palette: not installed"
        fi

        log::break

        local options=()
        if $installed; then
            options+=("Remove Palette")
        else
            options+=("Install Palette")
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
            ""|"Back") return ;;
            "Exit") ui::clear_content; ui::goodbye ;;
            "Install Palette") log::break; _appthemes::starship_install ;;
            "Remove Palette") log::break; _appthemes::starship_remove ;;
        esac
    done
}

# ── Task registry ──────────────────────────────────────────────────

_APPTHEMES_TASKS=(
    "${_BTOP_LABEL}|_BTOP_DESC|_appthemes::btop_installed|_appthemes::btop_apply|_appthemes::btop_status"
    "${_ALACRITTY_LABEL}|_ALACRITTY_DESC|_appthemes::alacritty_installed|_appthemes::alacritty_apply|_appthemes::alacritty_status"
    "${_ATUIN_LABEL}|_ATUIN_DESC|_appthemes::atuin_installed|_appthemes::atuin_apply|_appthemes::atuin_status"
    "${_BAT_LABEL}|_BAT_DESC|_appthemes::bat_installed|_appthemes::bat_apply|_appthemes::bat_status"
    "${_CAVA_LABEL}|_CAVA_DESC|_appthemes::cava_installed|_appthemes::cava_apply|_appthemes::cava_status"
    "${_EZA_LABEL}|_EZA_DESC|_appthemes::eza_installed|_appthemes::eza_apply|_appthemes::eza_status"
    "${_LAZYGIT_LABEL}|_LAZYGIT_DESC|_appthemes::lazygit_installed|_appthemes::lazygit_apply|_appthemes::lazygit_status"
    "${_STARSHIP_LABEL}|_STARSHIP_DESC|_appthemes::starship_installed|_appthemes::starship_apply|_appthemes::starship_status"
)

# ── Top-level functions ────────────────────────────────────────────

appthemes::check() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_APPTHEMES_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 1
        fi
    done
    return 0
}

appthemes::status() {
    local task label desc_var check_fn apply_fn status_fn
    local pending=0
    for task in "${_APPTHEMES_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    if [[ $pending -gt 0 ]]; then
        printf '%s app themes pending' "$pending"
    fi
}

appthemes::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "UI > App Themes"
        log::break

        local items=() apply_fns=()
        for task in "${_APPTHEMES_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            items+=("$label")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::filter \
            --height 11 \
            --header "Select an app theme:" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to filter..." \
            "${items[@]}")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local i
                for i in "${!items[@]}"; do
                    if [[ "${items[$i]}" == "$choice" ]]; then
                        "${apply_fns[$i]}"
                        break
                    fi
                done
                ;;
        esac
    done
}
