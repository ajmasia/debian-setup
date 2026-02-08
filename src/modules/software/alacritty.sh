# Alacritty terminal emulator task

[[ -n "${_MOD_ALACRITTY_LOADED:-}" ]] && return 0
_MOD_ALACRITTY_LOADED=1

_ALACRITTY_LABEL="Configure Alacritty"
_ALACRITTY_DESC="Install Alacritty terminal emulator (build from source)."
_ALACRITTY_BIN="/usr/local/bin/alacritty"
_ALACRITTY_REPO="https://github.com/alacritty/alacritty.git"
_ALACRITTY_BUILD_DEPS=(cmake g++ pkg-config libfontconfig1-dev libxcb-xfixes0-dev libxkbcommon-dev python3 scdoc libegl1-mesa-dev)

_alacritty::is_installed() {
    [[ -x "$_ALACRITTY_BIN" ]]
}

_alacritty::session_ready() {
    command -v alacritty &>/dev/null
}

alacritty::check() {
    _alacritty::is_installed && _alacritty::session_ready
}

alacritty::status() {
    local issues=()
    _alacritty::is_installed || issues+=("not installed")
    _alacritty::is_installed && ! _alacritty::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

alacritty::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _alacritty::is_installed && installed=true
        _alacritty::session_ready && session_ready=true

        ui::clear_content
        log::nav "Software > Terminals > Alacritty"
        log::break

        log::info "Alacritty"

        if $installed; then
            if $session_ready; then
                local version
                version="$(alacritty --version 2>/dev/null || true)"
                log::ok "Alacritty: ${version}"
            else
                log::ok "Alacritty: installed"
                log::warn "Restart needed to activate alacritty in current session"
            fi
        else
            log::warn "Alacritty (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Update Alacritty" "Remove Alacritty")
        else
            options+=("Install Alacritty")
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
            "Install Alacritty"|"Update Alacritty")
                log::break
                _alacritty::install
                ;;
            "Remove Alacritty")
                log::break
                _alacritty::remove
                ;;
        esac
    done
}

_alacritty::install() {
    # Check cargo availability
    local cargo_bin=""
    if command -v cargo &>/dev/null; then
        cargo_bin="cargo"
    elif [[ -x "$HOME/.cargo/bin/cargo" ]]; then
        cargo_bin="$HOME/.cargo/bin/cargo"
    fi

    if [[ -z "$cargo_bin" ]]; then
        log::error "Rust/cargo is required to build Alacritty"
        log::warn "Install Rust first via Development > Environments"
        return
    fi

    # Check and install build dependencies
    _alacritty::check_deps || return

    # Clone repo
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Cloning Alacritty repository"
    if ! git clone "$_ALACRITTY_REPO" "$tmpdir/alacritty" 2>/dev/null; then
        log::error "Failed to clone Alacritty repository"
        rm -rf "$tmpdir"
        return
    fi
    log::ok "Repository cloned"

    # Get latest stable tag
    local tag
    tag="$(cd "$tmpdir/alacritty" && git tag | grep -E '^v[0-9]' | sort -V | tail -1 || true)"

    if [[ -n "$tag" ]]; then
        (cd "$tmpdir/alacritty" && git checkout "$tag" 2>/dev/null || true)
        log::ok "Using version ${tag}"
    else
        log::warn "Could not determine latest tag, using HEAD"
    fi

    # Build
    log::info "Building Alacritty (this may take several minutes)"
    log::break

    if ! (cd "$tmpdir/alacritty" && "$cargo_bin" build --release); then
        log::break
        log::error "Build failed"
        rm -rf "$tmpdir"
        return
    fi

    log::break

    # Install binary
    log::info "Installing Alacritty binary"
    ui::flush_input
    sudo cp "$tmpdir/alacritty/target/release/alacritty" "$_ALACRITTY_BIN" </dev/tty
    log::ok "Binary installed to ${_ALACRITTY_BIN}"

    # Terminfo
    if [[ -f "$tmpdir/alacritty/extra/alacritty.info" ]]; then
        log::info "Installing terminfo entries"
        sudo tic -xe alacritty,alacritty-direct "$tmpdir/alacritty/extra/alacritty.info"
        log::ok "Terminfo installed"
    fi

    # Desktop integration
    _alacritty::desktop_integration "$tmpdir/alacritty"

    # Man pages
    _alacritty::install_man_pages "$tmpdir/alacritty"

    # Cleanup
    rm -rf "$tmpdir"
    hash -r

    log::break
    log::ok "Alacritty installed"
}

_alacritty::check_deps() {
    log::info "Checking build dependencies"

    local missing=()
    local dep
    for dep in "${_ALACRITTY_BUILD_DEPS[@]}"; do
        if apt::is_installed "$dep"; then
            log::ok "$dep"
        else
            log::warn "${dep} (not installed)"
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log::ok "All build dependencies installed"
        log::break
        return 0
    fi

    log::break
    local install
    install="$(gum::choose \
        --header "Install ${#missing[@]} missing build dependencies?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$install" != "Yes" ]]; then
        log::warn "Cannot build without dependencies"
        return 1
    fi

    log::info "Installing ${missing[*]}"
    log::break
    ui::flush_input
    if sudo apt-get install -y "${missing[@]}" </dev/tty; then
        hash -r
        log::break
        log::ok "Build dependencies installed"
        log::break
        return 0
    else
        hash -r
        log::break
        log::error "Failed to install build dependencies"
        return 1
    fi
}

_alacritty::desktop_integration() {
    local srcdir="$1"

    # Icon
    if [[ -f "$srcdir/extra/logo/alacritty-term.svg" ]]; then
        log::info "Installing desktop integration"
        ui::flush_input
        sudo cp "$srcdir/extra/logo/alacritty-term.svg" /usr/share/pixmaps/Alacritty.svg </dev/tty
        log::ok "Icon installed"
    fi

    # Desktop file
    if [[ -f "$srcdir/extra/linux/Alacritty.desktop" ]]; then
        sudo desktop-file-install "$srcdir/extra/linux/Alacritty.desktop"
        sudo update-desktop-database
        log::ok "Desktop entry installed"
    fi
}

_alacritty::install_man_pages() {
    local srcdir="$1"

    if ! command -v scdoc &>/dev/null; then
        return
    fi

    local man1_dir="/usr/local/share/man/man1"
    local man5_dir="/usr/local/share/man/man5"

    # man1 pages
    if [[ -f "$srcdir/extra/man/alacritty.1.scd" ]]; then
        log::info "Installing man pages"
        sudo mkdir -p "$man1_dir" "$man5_dir"

        if [[ -f "$srcdir/extra/man/alacritty.1.scd" ]]; then
            scdoc < "$srcdir/extra/man/alacritty.1.scd" | gzip -c | sudo tee "$man1_dir/alacritty.1.gz" > /dev/null
        fi

        if [[ -f "$srcdir/extra/man/alacritty-msg.1.scd" ]]; then
            scdoc < "$srcdir/extra/man/alacritty-msg.1.scd" | gzip -c | sudo tee "$man1_dir/alacritty-msg.1.gz" > /dev/null
        fi

        # man5 pages
        if [[ -f "$srcdir/extra/man/alacritty.5.scd" ]]; then
            scdoc < "$srcdir/extra/man/alacritty.5.scd" | gzip -c | sudo tee "$man5_dir/alacritty.5.gz" > /dev/null
        fi

        if [[ -f "$srcdir/extra/man/alacritty-bindings.5.scd" ]]; then
            scdoc < "$srcdir/extra/man/alacritty-bindings.5.scd" | gzip -c | sudo tee "$man5_dir/alacritty-bindings.5.gz" > /dev/null
        fi

        log::ok "Man pages installed"
    fi
}

_alacritty::remove() {
    log::info "Removing Alacritty"
    ui::flush_input

    sudo rm -f "$_ALACRITTY_BIN" </dev/tty
    sudo rm -f /usr/share/pixmaps/Alacritty.svg
    sudo rm -f /usr/share/applications/Alacritty.desktop
    sudo rm -f /usr/local/share/man/man1/alacritty.1.gz
    sudo rm -f /usr/local/share/man/man1/alacritty-msg.1.gz
    sudo rm -f /usr/local/share/man/man5/alacritty.5.gz
    sudo rm -f /usr/local/share/man/man5/alacritty-bindings.5.gz
    sudo update-desktop-database 2>/dev/null || true
    hash -r

    log::ok "Alacritty removed"
}
