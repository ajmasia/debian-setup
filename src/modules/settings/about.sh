# About debian-setup

[[ -n "${_MOD_ABOUT_LOADED:-}" ]] && return 0
_MOD_ABOUT_LOADED=1

about::run() {
    ui::clear_content
    log::nav "Settings > About"
    log::break

    log::info "debian-setup"
    log::ok "Version:       ${VERSION}"
    log::ok "Install path:  ${SCRIPT_DIR}"
    log::ok "Log directory: $(xdg::log_dir)"
    log::ok "Shell:         ${BASH_VERSION}"
    log::break

    ui::return_or_exit
}
