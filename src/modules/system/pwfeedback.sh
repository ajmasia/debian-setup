# Sudo password feedback task

[[ -n "${_MOD_PWFEEDBACK_LOADED:-}" ]] && return 0
_MOD_PWFEEDBACK_LOADED=1

_PWFEEDBACK_LABEL="Enable sudo password feedback"
_PWFEEDBACK_DESC="Adds 'Defaults pwfeedback' to /etc/sudoers.d/pwfeedback.
Shows asterisks when typing sudo passwords."

pwfeedback::check() {
    [[ -f "/etc/sudoers.d/pwfeedback" ]]
}

pwfeedback::apply() {
    log::info "Enabling sudo password feedback"
    log::break

    ui::flush_input

    if echo 'Defaults pwfeedback' | sudo tee /etc/sudoers.d/pwfeedback > /dev/null \
        && sudo chmod 0440 /etc/sudoers.d/pwfeedback; then
        log::ok "Password feedback enabled"
    else
        log::error "Failed to enable password feedback"
    fi
}
