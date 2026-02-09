# Slack task (Flatpak)

[[ -n "${_MOD_SLACK_LOADED:-}" ]] && return 0
_MOD_SLACK_LOADED=1

_SLACK_LABEL="Configure Slack"
_SLACK_DESC="Install Slack."
_SLACK_FLATPAK_ID="com.slack.Slack"

_slack::is_installed() {
    flatpak list --app --columns=application 2>/dev/null | grep -qF "$_SLACK_FLATPAK_ID"
}

slack::check() {
    _slack::is_installed
}

slack::status() {
    _slack::is_installed || printf 'not installed'
}

slack::apply() {
    local choice

    while true; do
        local installed=false
        _slack::is_installed && installed=true

        ui::clear_content
        log::nav "Software > Messaging > Slack"
        log::break

        log::info "Slack"

        if $installed; then
            local version
            version="$(flatpak info "$_SLACK_FLATPAK_ID" 2>/dev/null | awk '/Version:/{print $2}' || true)"
            log::ok "Slack: ${version}"
        else
            log::warn "Slack (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Remove Slack")
        else
            options+=("Install Slack")
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
            "Install Slack")
                log::break
                _slack::install
                ;;
            "Remove Slack")
                log::break
                _slack::remove
                ;;
        esac
    done
}

_slack::install() {
    if ! command -v flatpak &>/dev/null; then
        log::error "Flatpak not installed. Install via Package managers first"
        ui::return_or_exit
        return
    fi

    log::info "Installing Slack"
    if sudo flatpak install -y flathub "$_SLACK_FLATPAK_ID"; then
        log::ok "Slack installed"
    else
        log::error "Failed to install Slack"
    fi
    ui::return_or_exit
}

_slack::remove() {
    log::info "Removing Slack"
    if sudo flatpak remove -y "$_SLACK_FLATPAK_ID"; then
        log::ok "Slack removed"
    else
        log::error "Failed to remove Slack"
    fi
    ui::return_or_exit
}
