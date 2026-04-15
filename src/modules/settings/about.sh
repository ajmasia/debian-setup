# About debian-setup

[[ -n "${_MOD_ABOUT_LOADED:-}" ]] && return 0
_MOD_ABOUT_LOADED=1

_about::package_managers() {
    local managers=()
    local mgr
    for mgr in apt nala flatpak snap nix brew; do
        command -v "$mgr" &>/dev/null && managers+=("$mgr")
    done
    printf '%s' "${managers[*]}"
}

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

    log::info "System"
    log::ok "OS:            $(system::os)"
    log::ok "Packages:      $(_about::package_managers)"
    log::break

    ui::return_or_exit
}
