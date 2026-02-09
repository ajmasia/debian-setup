# Homebrew package manager task

[[ -n "${_MOD_HOMEBREW_LOADED:-}" ]] && return 0
_MOD_HOMEBREW_LOADED=1

_HOMEBREW_LABEL="Configure Homebrew"
_HOMEBREW_DESC="Install or remove the Homebrew package manager."

_HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
_HOMEBREW_UNINSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh"
_HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"

_homebrew::is_installed() {
    [[ -x "${_HOMEBREW_PREFIX}/bin/brew" ]]
}

_homebrew::session_ready() {
    command -v brew &>/dev/null
}

_homebrew::eval_env() {
    if _homebrew::is_installed && ! _homebrew::session_ready; then
        eval "$("${_HOMEBREW_PREFIX}/bin/brew" shellenv)"
    fi
}

homebrew::check() {
    _homebrew::is_installed && _homebrew::session_ready
}

homebrew::status() {
    local issues=()
    _homebrew::is_installed || issues+=("not installed")
    _homebrew::is_installed && ! _homebrew::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

homebrew::apply() {
    local choice

    while true; do
        local installed=false session_ready=false
        _homebrew::is_installed && installed=true
        _homebrew::session_ready && session_ready=true

        ui::clear_content
        log::nav "Package Managers > Homebrew"
        log::break

        log::info "Homebrew"

        if $installed; then
            if $session_ready; then
                local version
                version="$(brew --version 2>/dev/null | head -1 || true)"
                log::ok "Homebrew: ${version}"
            else
                log::ok "Homebrew: installed"
                log::warn "Restart needed to activate brew in current session"
            fi
        else
            log::warn "Homebrew (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            if $session_ready; then
                options+=("Update Homebrew")
            fi
            options+=("Remove Homebrew")
        else
            options+=("Install Homebrew")
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
            "Install Homebrew")
                log::break
                _homebrew::install
                ;;
            "Update Homebrew")
                log::break
                _homebrew::update
                ;;
            "Remove Homebrew")
                log::break
                _homebrew::remove
                ;;
        esac
    done
}

_homebrew::install() {
    # Homebrew needs build-essential, curl, git
    local deps=("build-essential" "curl" "git")
    local missing=()
    local pkg
    for pkg in "${deps[@]}"; do
        dpkg -l "$pkg" 2>/dev/null | grep -q '^ii' || missing+=("$pkg")
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
        log::break
    fi

    log::info "Installing Homebrew"
    log::break
    ui::flush_input
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$_HOMEBREW_INSTALL_URL")" </dev/tty; then
        log::break
        log::ok "Homebrew installed"

        # Add to .bashrc if not already present
        if [[ -f "$HOME/.bashrc" ]] && grep -Fq 'linuxbrew' "$HOME/.bashrc"; then
            log::ok "bashrc already configured"
        else
            printf '\n# Added by debian-setup: homebrew\neval "$(%s/bin/brew shellenv)"\n' "$_HOMEBREW_PREFIX" >> "$HOME/.bashrc"
            log::ok "Added brew shellenv to .bashrc"
        fi

        # Activate in current session
        _homebrew::eval_env

        log::break
        log::warn "Restart your shell for full activation"
    else
        log::break
        log::error "Homebrew installation failed"
    fi
}

_homebrew::update() {
    log::info "Updating Homebrew"
    if brew update; then
        log::ok "Homebrew updated"
    else
        log::error "Failed to update Homebrew"
    fi
}

_homebrew::remove() {
    log::info "Removing Homebrew"
    log::break
    ui::flush_input
    if NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$_HOMEBREW_UNINSTALL_URL")" </dev/tty; then
        log::break
        log::ok "Homebrew removed"

        # Clean .bashrc
        if [[ -f "$HOME/.bashrc" ]]; then
            local tmp
            tmp="$(mktemp)"
            grep -v 'linuxbrew' "$HOME/.bashrc" | grep -v 'debian-setup: homebrew' > "$tmp" || true
            mv "$tmp" "$HOME/.bashrc"
            log::ok "Cleaned .bashrc"
        fi

        # Clean leftover directory
        if [[ -d "$_HOMEBREW_PREFIX" ]]; then
            ui::flush_input
            sudo rm -rf "$_HOMEBREW_PREFIX" </dev/tty
            log::ok "Removed ${_HOMEBREW_PREFIX}"
        fi

        hash -r
        log::break
        log::warn "Restart your shell to complete cleanup"
    else
        log::break
        log::error "Failed to remove Homebrew"
    fi
}
