# Shell completions management

[[ -n "${_MOD_COMPLETIONS_LOADED:-}" ]] && return 0
_MOD_COMPLETIONS_LOADED=1

_COMPLETIONS_BASH_SRC="${SCRIPT_DIR}/completions/debian-setup.bash"
_COMPLETIONS_ZSH_SRC="${SCRIPT_DIR}/completions/debian-setup.zsh"
_COMPLETIONS_BASH_DIR="$HOME/.local/share/bash-completion/completions"
_COMPLETIONS_ZSH_DIR="$HOME/.local/share/zsh/site-functions"
_COMPLETIONS_BASH_LINK="${_COMPLETIONS_BASH_DIR}/debian-setup"
_COMPLETIONS_ZSH_LINK="${_COMPLETIONS_ZSH_DIR}/_debian-setup"

_completions::bash_installed() {
    [[ -L "$_COMPLETIONS_BASH_LINK" ]]
}

_completions::zsh_installed() {
    [[ -L "$_COMPLETIONS_ZSH_LINK" ]]
}

completions::run() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Settings > Completions"
        log::break

        log::info "Shell completions"

        if _completions::bash_installed; then
            log::ok "Bash completions installed"
        else
            log::warn "Bash completions (not installed)"
        fi

        if _completions::zsh_installed; then
            log::ok "Zsh completions installed"
        else
            log::warn "Zsh completions (not installed)"
        fi

        log::break

        local options=()

        if _completions::bash_installed && _completions::zsh_installed; then
            options+=("Reinstall completions" "Remove completions")
        elif _completions::bash_installed || _completions::zsh_installed; then
            options+=("Install completions" "Remove completions")
        else
            options+=("Install completions")
        fi

        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${options[@]}")"

        case "$choice" in
            "Install completions"|"Reinstall completions")
                _completions::install
                ;;
            "Remove completions")
                _completions::remove
                ;;
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}

_completions::install() {
    log::break

    # Bash
    mkdir -p "$_COMPLETIONS_BASH_DIR"
    ln -sf "$_COMPLETIONS_BASH_SRC" "$_COMPLETIONS_BASH_LINK"
    log::ok "Bash completions installed"

    # Zsh
    mkdir -p "$_COMPLETIONS_ZSH_DIR"
    ln -sf "$_COMPLETIONS_ZSH_SRC" "$_COMPLETIONS_ZSH_LINK"
    log::ok "Zsh completions installed"

    log::break
    log::warn "Restart your shell to activate completions"
}

_completions::remove() {
    log::break

    if [[ -L "$_COMPLETIONS_BASH_LINK" ]]; then
        rm "$_COMPLETIONS_BASH_LINK"
        log::ok "Bash completions removed"
    fi

    if [[ -L "$_COMPLETIONS_ZSH_LINK" ]]; then
        rm "$_COMPLETIONS_ZSH_LINK"
        log::ok "Zsh completions removed"
    fi

    log::break
    log::warn "Restart your shell to deactivate completions"
}
