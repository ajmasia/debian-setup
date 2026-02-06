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
    log::info "Installing gum (sudo may ask for your password)"
    log::break

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://repo.charm.sh/apt/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/charm.gpg
    echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -y gum

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
    gum choose "$@"
}
