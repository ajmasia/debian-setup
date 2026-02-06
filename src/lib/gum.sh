# Gum wrapper functions
# https://github.com/charmbracelet/gum

[[ -n "${_LIB_GUM_LOADED:-}" ]] && return 0
_LIB_GUM_LOADED=1

gum::check() {
    if ! command -v gum &>/dev/null; then
        log::error "gum is required but not installed"
        log::info "Install it from: https://github.com/charmbracelet/gum#installation"
        exit 1
    fi
}

gum::style() {
    gum style "$@"
}

gum::choose() {
    gum choose "$@"
}
