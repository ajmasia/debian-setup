# GitHub CLI task

[[ -n "${_MOD_GHCLI_LOADED:-}" ]] && return 0
_MOD_GHCLI_LOADED=1

_GHCLI_LABEL="Configure GitHub CLI"
_GHCLI_DESC="Install GitHub CLI (gh)."

_GHCLI_GPG_URL="https://cli.github.com/packages/githubcli-archive-keyring.gpg"
_GHCLI_GPG_KEY="/usr/share/keyrings/githubcli-archive-keyring.gpg"
_GHCLI_SOURCES="/etc/apt/sources.list.d/github-cli.sources"

_ghcli::is_installed() {
    dpkg -l gh 2>/dev/null | grep -q '^ii'
}

ghcli::check() {
    _ghcli::is_installed
}

ghcli::status() {
    _ghcli::is_installed || printf 'not installed'
}

ghcli::apply() {
    local choice

    while true; do
        local installed=false
        _ghcli::is_installed && installed=true

        ui::clear_content
        log::nav "Development > Tools > GitHub CLI"
        log::break

        log::info "GitHub CLI"

        if $installed; then
            local version
            version="$(gh --version 2>/dev/null | head -1 || true)"
            log::ok "gh: ${version}"
        else
            log::warn "gh (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove GitHub CLI")
        else
            options+=("Install GitHub CLI")
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
            "Install GitHub CLI")
                log::break
                _ghcli::install
                ;;
            "Remove GitHub CLI")
                log::break
                _ghcli::remove
                ;;
        esac
    done
}

_ghcli::install() {
    log::info "Adding GitHub CLI repository"
    ui::flush_input

    if ! sudo curl -fsSLo "$_GHCLI_GPG_KEY" "$_GHCLI_GPG_URL" </dev/tty; then
        log::error "Failed to download GitHub CLI GPG key"
        ui::return_or_exit
        return
    fi
    sudo chmod 644 "$_GHCLI_GPG_KEY"

    local arch
    arch="$(dpkg --print-architecture)"

    local sources_content
    sources_content="$(cat <<EOF
Types: deb
URIs: https://cli.github.com/packages
Suites: stable
Components: main
Architectures: ${arch}
Signed-By: ${_GHCLI_GPG_KEY}
EOF
)"

    printf '%s\n' "$sources_content" | sudo tee "$_GHCLI_SOURCES" > /dev/null
    sudo chmod 644 "$_GHCLI_SOURCES"
    log::ok "Repository added"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing GitHub CLI"
    if sudo apt-get install -y gh </dev/tty; then
        hash -r
        log::ok "GitHub CLI installed"
    else
        log::error "Failed to install GitHub CLI"
    fi
    ui::return_or_exit
}

_ghcli::remove() {
    log::info "Removing GitHub CLI"
    ui::flush_input
    if sudo apt-get remove -y gh </dev/tty; then
        hash -r
        log::ok "GitHub CLI removed"
    else
        log::error "Failed to remove GitHub CLI"
        ui::return_or_exit
        return
    fi

    if [[ -f "$_GHCLI_SOURCES" ]]; then
        sudo rm -f "$_GHCLI_SOURCES"
        log::ok "GitHub CLI repository removed"
    fi
    if [[ -f "$_GHCLI_GPG_KEY" ]]; then
        sudo rm -f "$_GHCLI_GPG_KEY"
        log::ok "GitHub CLI GPG key removed"
    fi
    ui::return_or_exit
}
