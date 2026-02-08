# Docker CE task

[[ -n "${_MOD_DOCKER_LOADED:-}" ]] && return 0
_MOD_DOCKER_LOADED=1

_DOCKER_LABEL="Configure Docker"
_DOCKER_DESC="Install or remove Docker CE."

_DOCKER_GPG_URL="https://download.docker.com/linux/debian/gpg"
_DOCKER_GPG_KEY="/usr/share/keyrings/docker-archive-keyring.gpg"
_DOCKER_SOURCES="/etc/apt/sources.list.d/docker.sources"
_DOCKER_PACKAGES="docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

_docker::is_installed() {
    dpkg -l docker-ce 2>/dev/null | grep -q '^ii'
}

# User belongs to docker group (on disk, in /etc/group)
_docker::user_in_group() {
    getent group docker 2>/dev/null | grep -qw "$USER"
}

# Current session has docker group active (no sudo needed)
_docker::session_ready() {
    id -nG 2>/dev/null | grep -qw docker
}

docker::check() {
    _docker::is_installed && _docker::session_ready
}

docker::status() {
    local issues=()
    _docker::is_installed || issues+=("not installed")
    if _docker::is_installed; then
        if ! _docker::user_in_group; then
            issues+=("user not in docker group")
        elif ! _docker::session_ready; then
            issues+=("restart needed")
        fi
    fi
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

docker::apply() {
    local choice

    while true; do
        local installed=false in_group=false session_ready=false
        _docker::is_installed && installed=true
        _docker::user_in_group && in_group=true
        _docker::session_ready && session_ready=true

        ui::clear_content
        log::nav "Development > Tools > Docker"
        log::break

        log::info "Docker"

        if $installed; then
            local version
            version="$(docker --version 2>/dev/null || true)"
            log::ok "Docker: ${version}"

            if $session_ready; then
                log::ok "User ${USER} in docker group (active)"
            elif $in_group; then
                log::ok "User ${USER} added to docker group"
                log::warn "Restart session to use docker without sudo"
            else
                log::warn "User ${USER} not in docker group (requires sudo)"
            fi
        else
            log::warn "Docker (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            if ! $in_group; then
                options+=("Add user to docker group")
            fi
            options+=("Remove Docker")
        else
            options+=("Install Docker")
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
            "Install Docker")
                log::break
                _docker::install
                ;;
            "Add user to docker group")
                log::break
                _docker::add_user_to_group
                ;;
            "Remove Docker")
                log::break
                _docker::remove
                ;;
        esac
    done
}

_docker::install() {
    log::info "Adding Docker repository"
    ui::flush_input

    # Download GPG key and dearmor
    if ! curl -fsSL "$_DOCKER_GPG_URL" | sudo gpg --dearmor -o "$_DOCKER_GPG_KEY"; then
        log::error "Failed to download Docker GPG key"
        return
    fi
    sudo chmod 644 "$_DOCKER_GPG_KEY"

    local arch codename
    arch="$(dpkg --print-architecture)"
    codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"

    local sources_content
    sources_content="$(cat <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: ${codename}
Components: stable
Architectures: ${arch}
Signed-By: ${_DOCKER_GPG_KEY}
EOF
)"

    printf '%s\n' "$sources_content" | sudo tee "$_DOCKER_SOURCES" > /dev/null
    sudo chmod 644 "$_DOCKER_SOURCES"
    log::ok "Repository added"

    log::info "Updating package lists"
    if ! sudo apt-get update </dev/tty; then
        log::warn "apt-get update finished with warnings"
    fi

    log::info "Installing Docker"
    # shellcheck disable=SC2086
    if sudo apt-get install -y $_DOCKER_PACKAGES </dev/tty; then
        hash -r
        log::ok "Docker installed"
        log::break

        local add_group
        add_group="$(gum::choose \
            --header "Add ${USER} to docker group? (avoids sudo)" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Yes" "No")"

        if [[ "$add_group" == "Yes" ]]; then
            _docker::add_user_to_group
        fi
    else
        log::error "Failed to install Docker"
    fi
}

_docker::add_user_to_group() {
    log::info "Adding ${USER} to docker group"
    ui::flush_input
    if sudo usermod -aG docker "$USER" </dev/tty; then
        log::ok "User added to docker group"
        log::break
        log::warn "Log out and back in (or restart) to use docker without sudo"
    else
        log::error "Failed to add user to docker group"
    fi
}

_docker::remove() {
    log::info "Removing Docker"
    ui::flush_input
    # shellcheck disable=SC2086
    if sudo apt-get remove -y $_DOCKER_PACKAGES </dev/tty; then
        hash -r
        log::ok "Docker removed"
    else
        log::error "Failed to remove Docker"
        return
    fi

    if [[ -f "$_DOCKER_SOURCES" ]]; then
        sudo rm -f "$_DOCKER_SOURCES"
        log::ok "Docker repository removed"
    fi
    if [[ -f "$_DOCKER_GPG_KEY" ]]; then
        sudo rm -f "$_DOCKER_GPG_KEY"
        log::ok "Docker GPG key removed"
    fi
}
