# Sudo password feedback task

[[ -n "${_MOD_PWFEEDBACK_LOADED:-}" ]] && return 0
_MOD_PWFEEDBACK_LOADED=1

_PWFEEDBACK_LABEL="Configure password feedback"
_PWFEEDBACK_DESC="Manage 'Defaults pwfeedback' in /etc/sudoers.d/pwfeedback."

pwfeedback::check() {
    [[ -f "/etc/sudoers.d/pwfeedback" ]]
}

pwfeedback::status() {
    if ! pwfeedback::check; then
        printf '%s' "not enabled"
    fi
}

pwfeedback::apply() {
    local choice

    while true; do
        local enabled=false
        pwfeedback::check && enabled=true

        ui::clear_content
        log::nav "System core > Configure password feedback"
        log::break

        log::info "Current password feedback configuration"

        if $enabled; then
            log::ok "Password feedback: enabled (asterisks shown)"
        else
            log::warn "Password feedback: disabled"
        fi

        log::break

        local options=()
        if $enabled; then
            options+=("Disable password feedback")
        else
            options+=("Enable password feedback")
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
            "Enable password feedback")
                log::break
                log::info "Enabling sudo password feedback"
                ui::flush_input
                if echo 'Defaults pwfeedback' | sudo tee /etc/sudoers.d/pwfeedback > /dev/null \
                    && sudo chmod 0440 /etc/sudoers.d/pwfeedback; then
                    log::ok "Password feedback enabled"
                    return
                else
                    log::error "Failed to enable password feedback"
                fi
                ;;
            "Disable password feedback")
                log::break
                log::info "Disabling sudo password feedback"
                ui::flush_input
                if sudo rm /etc/sudoers.d/pwfeedback </dev/tty; then
                    log::ok "Password feedback disabled"
                    return
                else
                    log::error "Failed to disable password feedback"
                fi
                ;;
        esac
    done
}
