# Gum wrapper functions
# https://github.com/charmbracelet/gum

[[ -n "${_LIB_GUM_LOADED:-}" ]] && return 0
_LIB_GUM_LOADED=1

gum::_install() {
    local response

    log::warn "gum is required but not installed"
    log::info "https://github.com/charmbracelet/gum"
    log::break

    printf "%b%s%b " "${COLOR_YELLOW}" "Install gum now? [y/N]" "${COLOR_RESET}"
    read -r response

    if [[ "${response,,}" != "y" ]]; then
        log::error "Cannot continue without gum"
        exit 1
    fi

    log::break

    # Detect if user has sudo access
    local use_sudo=true
    if ! sudo -n true 2>/dev/null && ! groups | grep -qw sudo; then
        use_sudo=false
        log::info "Installing gum (root password required)"
    else
        log::info "Installing gum (sudo may ask for your password)"
    fi

    log::break

    local tmpkey
    tmpkey="$(mktemp)"
    if ! curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o "$tmpkey" 2>/dev/null; then
        rm -f "$tmpkey"
        log::error "Failed to download GPG key"
        exit 1
    fi

    if $use_sudo; then
        sudo mkdir -p /etc/apt/keyrings
        sudo mv "$tmpkey" /etc/apt/keyrings/charm.gpg
        sudo chmod 644 /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y gum
    else
        su -c "
            mkdir -p /etc/apt/keyrings
            mv '$tmpkey' /etc/apt/keyrings/charm.gpg
            chmod 644 /etc/apt/keyrings/charm.gpg
            echo 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' > /etc/apt/sources.list.d/charm.list
            apt-get update -qq
            apt-get install -y gum
        " </dev/tty
    fi

    if ! command -v gum &>/dev/null; then
        log::error "gum installation failed"
        exit 1
    fi

    log::break
    log::ok "gum installed successfully"
    log::break
}

gum::check() {
    if ! command -v gum &>/dev/null; then
        gum::_install
    fi
}

gum::style() {
    gum style "$@"
}

gum::choose() {
    local rc=0
    gum choose "$@" || rc=$?
    [[ $rc -eq 130 ]] && exit 130
    return 0
}

gum::filter() {
    local rc=0
    gum filter "$@" || rc=$?
    [[ $rc -eq 130 ]] && exit 130
    return 0
}

gum::input() {
    local rc=0
    gum input "$@" || rc=$?
    [[ $rc -eq 130 ]] && exit 130
    return 0
}
