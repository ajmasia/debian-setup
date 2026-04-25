# GitHub Copilot CLI task

[[ -n "${_MOD_COPILOT_LOADED:-}" ]] && return 0
_MOD_COPILOT_LOADED=1

_COPILOT_LABEL="Configure GitHub Copilot CLI"
_COPILOT_DESC="Install or remove GitHub Copilot CLI (gh extension)."

_copilot::is_installed() {
    gh copilot --version &>/dev/null
}

copilot::check() {
    _copilot::is_installed
}

copilot::status() {
    _copilot::is_installed || printf 'not installed'
}

copilot::apply() {
    local choice

    while true; do
        local installed=false
        _copilot::is_installed && installed=true

        ui::clear_content
        log::nav "Development > AI > GitHub Copilot CLI"
        log::break

        log::info "GitHub Copilot CLI"

        if $installed; then
            local version
            version="$(gh copilot --version 2>/dev/null || true)"
            log::ok "Copilot CLI: ${version}"
        else
            log::warn "GitHub Copilot CLI (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Copilot CLI")
        else
            options+=("Install Copilot CLI")
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
            "Install Copilot CLI")
                log::break
                _copilot::install
                ;;
            "Remove Copilot CLI")
                log::break
                _copilot::remove
                ;;
        esac
    done
}

_copilot::install() {
    if ! command -v gh &>/dev/null; then
        log::error "GitHub CLI (gh) not available. Install it first (Development > Tools > GitHub CLI)"
        ui::return_or_exit
        return
    fi

    log::info "Installing GitHub Copilot CLI"
    if gh extension install github/gh-copilot; then
        log::ok "GitHub Copilot CLI installed"
    else
        log::error "Failed to install GitHub Copilot CLI"
    fi
    ui::return_or_exit
}

_copilot::remove() {
    log::info "Removing GitHub Copilot CLI"
    if gh extension remove gh-copilot; then
        log::ok "GitHub Copilot CLI removed"
    else
        log::error "Failed to remove GitHub Copilot CLI"
    fi
    ui::return_or_exit
}
