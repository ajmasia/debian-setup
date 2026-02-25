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

_completions::current_shell() {
    basename "${SHELL:-unknown}"
}

completions::run() {
    local choice current_shell

    while true; do
        ui::clear_content
        log::nav "Settings > Completions"
        log::break

        current_shell="$(_completions::current_shell)"

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

        # Bash
        local bash_suffix=""
        [[ "$current_shell" == "bash" ]] && bash_suffix=" (current shell)"

        if _completions::bash_installed; then
            options+=("Remove Bash completions${bash_suffix}")
        else
            options+=("Install Bash completions${bash_suffix}")
        fi

        # Zsh
        local zsh_suffix=""
        [[ "$current_shell" == "zsh" ]] && zsh_suffix=" (current shell)"

        if _completions::zsh_installed; then
            options+=("Remove Zsh completions${zsh_suffix}")
        else
            options+=("Install Zsh completions${zsh_suffix}")
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
            "Install Bash completions"*)
                log::break
                mkdir -p "$_COMPLETIONS_BASH_DIR"
                ln -sf "$_COMPLETIONS_BASH_SRC" "$_COMPLETIONS_BASH_LINK"
                menu::list > /dev/null
                log::ok "Bash completions installed"
                log::warn "Restart your shell to activate"
                ;;
            "Remove Bash completions"*)
                log::break
                rm "$_COMPLETIONS_BASH_LINK"
                log::ok "Bash completions removed"
                log::warn "Restart your shell to deactivate"
                ;;
            "Install Zsh completions"*)
                log::break
                mkdir -p "$_COMPLETIONS_ZSH_DIR"
                ln -sf "$_COMPLETIONS_ZSH_SRC" "$_COMPLETIONS_ZSH_LINK"
                menu::list > /dev/null
                log::ok "Zsh completions installed"
                log::warn "Restart your shell to activate"
                ;;
            "Remove Zsh completions"*)
                log::break
                rm "$_COMPLETIONS_ZSH_LINK"
                log::ok "Zsh completions removed"
                log::warn "Restart your shell to deactivate"
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
