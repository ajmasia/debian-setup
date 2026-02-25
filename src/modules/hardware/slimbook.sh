# Slimbook EVO setup task

[[ -n "${_MOD_SLIMBOOK_LOADED:-}" ]] && return 0
_MOD_SLIMBOOK_LOADED=1

_SLIMBOOK_LABEL="Configure Slimbook"
_SLIMBOOK_DESC="Install Slimbook repository and EVO/GNOME meta-packages."

_SLIMBOOK_GPG_URL="https://raw.githubusercontent.com/Slimbook-Team/slimbook-base-files/main/keys/slimbook.gpg"
_SLIMBOOK_LIST_URL="https://raw.githubusercontent.com/Slimbook-Team/slimbook-base-files/main/sources/slimbook.list"
_SLIMBOOK_GPG_PATH="/etc/apt/trusted.gpg.d/slimbook.gpg"
_SLIMBOOK_LIST_PATH="/etc/apt/sources.list.d/slimbook.list"

_SLIMBOOK_PACKAGES=("slimbook-meta-evo" "slimbook-meta-gnome")

_slimbook::has_repo() {
    [[ -f "$_SLIMBOOK_LIST_PATH" ]] && [[ -f "$_SLIMBOOK_GPG_PATH" ]]
}

_slimbook::pkg_installed() {
    dpkg -l "$1" 2>/dev/null | grep -q '^ii'
}

_slimbook::all_installed() {
    local pkg
    for pkg in "${_SLIMBOOK_PACKAGES[@]}"; do
        _slimbook::pkg_installed "$pkg" || return 1
    done
    return 0
}

slimbook::check() {
    _slimbook::has_repo && _slimbook::all_installed
}

slimbook::status() {
    local issues=()
    _slimbook::has_repo || issues+=("repo not configured")
    local pkg
    for pkg in "${_SLIMBOOK_PACKAGES[@]}"; do
        _slimbook::pkg_installed "$pkg" || issues+=("${pkg} not installed")
    done
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

slimbook::apply() {
    local choice

    while true; do
        local repo_ok=false all_ok=false
        _slimbook::has_repo && repo_ok=true
        _slimbook::all_installed && all_ok=true

        ui::clear_content
        log::nav "Hardware > Slimbook EVO setup"
        log::break

        log::info "Current Slimbook configuration"

        if $repo_ok; then
            log::ok "Slimbook repository: configured"
        else
            log::warn "Slimbook repository: not configured"
        fi

        local pkg
        for pkg in "${_SLIMBOOK_PACKAGES[@]}"; do
            if _slimbook::pkg_installed "$pkg"; then
                log::ok "${pkg}: installed"
            else
                log::warn "${pkg}: not installed"
            fi
        done

        log::break

        local options=()
        if ! $repo_ok || ! $all_ok; then
            options+=("Install Slimbook EVO packages")
        fi
        if $repo_ok || $all_ok; then
            options+=("Remove Slimbook EVO packages")
        fi
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
            "Install Slimbook EVO packages")
                log::break
                _slimbook::_install
                ;;
            "Remove Slimbook EVO packages")
                log::break
                _slimbook::_remove
                ;;
        esac
    done
}

_slimbook::_install() {
    # Add repository if missing
    if ! _slimbook::has_repo; then
        log::info "Adding Slimbook repository"

        local tmp_gpg tmp_list
        tmp_gpg="$(mktemp)"
        tmp_list="$(mktemp)"
        trap "rm -f '$tmp_gpg' '$tmp_list'" RETURN

        if ! curl -fsSL "$_SLIMBOOK_GPG_URL" -o "$tmp_gpg"; then
            log::error "Failed to download Slimbook GPG key"
            return
        fi

        if ! curl -fsSL "$_SLIMBOOK_LIST_URL" -o "$tmp_list"; then
            log::error "Failed to download Slimbook sources list"
            return
        fi

        ui::flush_input
        sudo mv "$tmp_gpg" "$_SLIMBOOK_GPG_PATH" </dev/tty \
            && sudo chmod 644 "$_SLIMBOOK_GPG_PATH" \
            && sudo mv "$tmp_list" "$_SLIMBOOK_LIST_PATH" </dev/tty \
            && sudo chmod 644 "$_SLIMBOOK_LIST_PATH"

        if ! _slimbook::has_repo; then
            log::error "Failed to configure Slimbook repository"
            return
        fi

        log::ok "Slimbook repository added"
        log::info "Updating APT cache"
        if sudo apt-get update -qq </dev/tty; then
            log::ok "APT cache updated"
        else
            log::warn "APT update finished with warnings"
        fi
    fi

    # Install packages
    local to_install=()
    local pkg
    for pkg in "${_SLIMBOOK_PACKAGES[@]}"; do
        _slimbook::pkg_installed "$pkg" || to_install+=("$pkg")
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        log::ok "All Slimbook packages already installed"
        return
    fi

    log::info "Installing: ${to_install[*]}"
    ui::flush_input
    if sudo apt install -y "${to_install[@]}" </dev/tty; then
        hash -r
        log::ok "Slimbook EVO packages installed"
    else
        log::error "Failed to install Slimbook packages"
    fi
}

_slimbook::_remove() {
    # Remove packages
    local to_remove=()
    local pkg
    for pkg in "${_SLIMBOOK_PACKAGES[@]}"; do
        _slimbook::pkg_installed "$pkg" && to_remove+=("$pkg")
    done

    if [[ ${#to_remove[@]} -gt 0 ]]; then
        log::info "Removing: ${to_remove[*]}"
        ui::flush_input
        if sudo apt remove -y "${to_remove[@]}" </dev/tty; then
            hash -r
            log::ok "Slimbook packages removed"
        else
            log::error "Failed to remove Slimbook packages"
            return
        fi
    fi

    # Ask to remove repository
    if _slimbook::has_repo; then
        local remove_repo
        remove_repo="$(gum::choose \
            --header "Also remove Slimbook repository?" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Yes" "No")"

        if [[ "$remove_repo" == "Yes" ]]; then
            log::info "Removing Slimbook repository"
            ui::flush_input
            sudo rm -f "$_SLIMBOOK_GPG_PATH" "$_SLIMBOOK_LIST_PATH" </dev/tty
            log::ok "Slimbook repository removed"
            log::info "Updating APT cache"
            if sudo apt-get update -qq </dev/tty; then
                log::ok "APT cache updated"
            else
                log::warn "APT update finished with warnings"
            fi
        fi
    fi
}
