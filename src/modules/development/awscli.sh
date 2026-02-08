# AWS CLI v2 task

[[ -n "${_MOD_AWSCLI_LOADED:-}" ]] && return 0
_MOD_AWSCLI_LOADED=1

_AWSCLI_LABEL="Configure AWS CLI"
_AWSCLI_DESC="Install or remove AWS CLI v2."

_awscli::is_installed() {
    command -v aws &>/dev/null
}

awscli::check() {
    _awscli::is_installed
}

awscli::status() {
    _awscli::is_installed || printf 'not installed'
}

awscli::apply() {
    local choice

    while true; do
        local installed=false
        _awscli::is_installed && installed=true

        ui::clear_content
        log::nav "Development > Tools > AWS CLI"
        log::break

        log::info "AWS CLI"

        if $installed; then
            local version
            version="$(aws --version 2>/dev/null || true)"
            log::ok "aws: ${version}"
        else
            log::warn "AWS CLI (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove AWS CLI")
        else
            options+=("Install AWS CLI")
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
            "Install AWS CLI")
                log::break
                _awscli::install
                ;;
            "Remove AWS CLI")
                log::break
                _awscli::remove
                ;;
        esac
    done
}

_awscli::install() {
    log::info "Installing AWS CLI v2"

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64)  arch="x86_64" ;;
        aarch64) arch="aarch64" ;;
        *)
            log::error "Unsupported architecture: ${arch}"
            return
            ;;
    esac

    local url="https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    log::info "Downloading AWS CLI"
    if ! curl -fsSL "$url" -o "${tmp_dir}/awscliv2.zip"; then
        rm -rf "$tmp_dir"
        log::error "Failed to download AWS CLI"
        return
    fi

    log::info "Extracting"
    if ! unzip -q "${tmp_dir}/awscliv2.zip" -d "$tmp_dir"; then
        rm -rf "$tmp_dir"
        log::error "Failed to extract AWS CLI"
        return
    fi

    log::info "Installing"
    ui::flush_input
    if sudo "${tmp_dir}/aws/install" </dev/tty; then
        hash -r
        log::ok "AWS CLI installed"
    else
        log::error "Failed to install AWS CLI"
    fi

    rm -rf "$tmp_dir"
}

_awscli::remove() {
    log::info "Removing AWS CLI"
    ui::flush_input
    sudo rm -rf /usr/local/aws-cli /usr/local/bin/aws /usr/local/bin/aws_completer </dev/tty
    hash -r
    log::ok "AWS CLI removed"
}
