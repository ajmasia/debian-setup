# SSH key generation task

[[ -n "${_MOD_SSH_KEYS_LOADED:-}" ]] && return 0
_MOD_SSH_KEYS_LOADED=1

_SSH_KEYS_LABEL="Configure SSH Keys"
_SSH_KEYS_DESC="Generate and manage ED25519 SSH keys."

_ssh_keys::has_ed25519() {
    compgen -G "$HOME/.ssh/id_ed25519*" &>/dev/null
}

_ssh_keys::list_keys() {
    local key_file
    for key_file in "$HOME"/.ssh/*.pub; do
        [[ -f "$key_file" ]] || continue
        local type comment
        type="$(awk '{print $1}' "$key_file")"
        comment="$(awk '{print $3}' "$key_file")"
        printf "  %s  %s  (%s)\n" "$(basename "$key_file")" "${comment:--}" "$type"
    done
}

ssh_keys::check() {
    _ssh_keys::has_ed25519
}

ssh_keys::status() {
    if ! _ssh_keys::has_ed25519; then
        printf '%s' "no ed25519 key"
    fi
}

ssh_keys::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "OpenSSH Server > SSH Keys"
        log::break

        log::info "Current SSH keys"

        local key_list
        key_list="$(_ssh_keys::list_keys)"
        if [[ -n "$key_list" ]]; then
            printf "%b%s%b\n" "${COLOR_OVERLAY1}" "$key_list" "${COLOR_RESET}"
        else
            log::warn "No SSH keys found"
        fi

        log::break

        local options=()
        options+=("Generate new ED25519 key")
        if compgen -G "$HOME/.ssh/*.pub" &>/dev/null; then
            options+=("Show public key")
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
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            "Generate new ED25519 key")
                log::break
                _ssh_keys::_generate
                ;;
            "Show public key")
                log::break
                _ssh_keys::_show_pubkey
                ;;
        esac
    done
}

_ssh_keys::_generate() {
    # Get email for comment
    local git_email default_email email hostname_str comment key_name key_path

    git_email="$(git config --global user.email 2>/dev/null || true)"
    default_email="${git_email:-user@example.com}"

    email="$(gum::input \
        --header "Email for key comment:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "$default_email" \
        --placeholder "your@email.com")"

    if [[ -z "$email" ]]; then
        log::warn "No email provided, cancelled"
        return
    fi

    hostname_str="$(system::hostname)"
    comment="${email} - ${hostname_str}"

    # Key name: if default exists, ask for suffix
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        local suffix
        suffix="$(gum::input \
            --header "id_ed25519 exists. Enter suffix for new key:" \
            --header.foreground "$HEX_LAVENDER" \
            --placeholder "github")"

        if [[ -z "$suffix" ]]; then
            log::warn "No suffix provided, cancelled"
            return
        fi

        key_name="id_ed25519_${suffix}"
    else
        key_name="id_ed25519"
    fi

    key_path="$HOME/.ssh/${key_name}"

    if [[ -f "$key_path" ]]; then
        log::warn "Key ${key_path} already exists"
        return
    fi

    # Ensure .ssh directory exists
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    log::info "Generating ED25519 key: ${key_path}"
    log::info "Comment: ${comment}"
    log::break

    ui::flush_input
    if ssh-keygen -t ed25519 -C "$comment" -f "$key_path" </dev/tty; then
        log::break
        log::ok "SSH key generated: ${key_path}"
        log::break
        log::info "Public key:"
        printf "%b%s%b\n" "${COLOR_GREEN}" "$(cat "${key_path}.pub")" "${COLOR_RESET}"

        # Ask to add to commit signing
        log::break
        local add_signing
        add_signing="$(gum::choose \
            --header "Add to commit signing?" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Yes" "No")"
        if [[ "$add_signing" == "Yes" ]]; then
            log::break
            ssh_signing::setup_key "$(basename "${key_path}.pub")"
        fi
    else
        log::break
        log::error "Failed to generate SSH key"
    fi
}

_ssh_keys::_show_pubkey() {
    local pub_files=()
    local f
    for f in "$HOME"/.ssh/*.pub; do
        [[ -f "$f" ]] || continue
        pub_files+=("$(basename "$f")")
    done

    if [[ ${#pub_files[@]} -eq 0 ]]; then
        log::warn "No public keys found"
        return
    fi

    local selected
    selected="$(gum::choose \
        --header "Select a public key:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pub_files[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    log::info "Public key: ${selected}"
    log::break
    printf "%b%s%b\n" "${COLOR_GREEN}" "$(cat "$HOME/.ssh/${selected}")" "${COLOR_RESET}"
    ui::return_or_exit
}
