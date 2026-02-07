# Git commit signing configuration task

[[ -n "${_MOD_SSH_SIGNING_LOADED:-}" ]] && return 0
_MOD_SSH_SIGNING_LOADED=1

_SSH_SIGNING_LABEL="Configure commit signing"
_SSH_SIGNING_DESC="Configure git commit signing with SSH keys and allowed signers."

_SSH_ALLOWED_SIGNERS="$HOME/.ssh/allowed_signers"

_ssh_signing::has_format() {
    [[ "$(git config --global gpg.format 2>/dev/null || true)" == "ssh" ]]
}

_ssh_signing::has_key() {
    local key
    key="$(git config --global user.signingkey 2>/dev/null || true)"
    [[ -n "$key" ]]
}

_ssh_signing::has_autosign() {
    [[ "$(git config --global commit.gpgsign 2>/dev/null || true)" == "true" ]]
}

_ssh_signing::has_conditional() {
    git config --global --get-regexp 'includeIf\..*\.path' &>/dev/null
}

ssh_signing::check() {
    _ssh_signing::has_format || return 1
    _ssh_signing::has_autosign || return 1
    _ssh_signing::has_key && return 0
    _ssh_signing::has_conditional && return 0
    return 1
}

ssh_signing::status() {
    local issues=()
    _ssh_signing::has_format || issues+=("gpg.format not ssh")
    local has_signing=false
    _ssh_signing::has_key && has_signing=true
    _ssh_signing::has_conditional && has_signing=true
    $has_signing || issues+=("no signing key")
    _ssh_signing::has_autosign || issues+=("auto-sign not enabled")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

ssh_signing::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "OpenSSH server > Configure commit signing"
        log::break

        log::info "Current commit signing configuration"

        if _ssh_signing::has_format; then
            log::ok "gpg.format: ssh"
        else
            log::warn "gpg.format: not set to ssh"
        fi

        if _ssh_signing::has_key; then
            local current_key
            current_key="$(git config --global user.signingkey 2>/dev/null || true)"
            log::ok "Signing key: ${current_key}"
        else
            log::warn "Signing key: not configured (global)"
        fi

        # Show conditional configs
        local includes
        includes="$(git config --global --get-regexp 'includeIf\..*\.path' 2>/dev/null || true)"
        if [[ -n "$includes" ]]; then
            while IFS= read -r line; do
                local key val gitdir
                key="${line%% *}"
                val="${line#* }"
                gitdir="${key#includeIf.gitdir:}"
                gitdir="${gitdir%.path}"
                log::ok "Conditional: ${val} (${gitdir})"
            done <<< "$includes"
        fi

        if _ssh_signing::has_autosign; then
            log::ok "Auto-sign commits: enabled"
        else
            log::warn "Auto-sign commits: disabled"
        fi

        if [[ -f "$_SSH_ALLOWED_SIGNERS" ]]; then
            log::ok "Allowed signers: configured"
        else
            log::warn "Allowed signers: not configured"
        fi

        log::break

        local options=()
        options+=("Setup commit signing")
        if ! [[ -f "$_SSH_ALLOWED_SIGNERS" ]]; then
            options+=("Configure allowed signers")
        else
            options+=("Update allowed signers")
        fi
        local has_config=false
        _ssh_signing::has_format && has_config=true
        _ssh_signing::has_key && has_config=true
        _ssh_signing::has_autosign && has_config=true
        _ssh_signing::has_conditional && has_config=true
        $has_config && options+=("Remove signing config")
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
            "Setup commit signing")
                log::break
                _ssh_signing::_setup
                ;;
            "Configure allowed signers"|"Update allowed signers")
                log::break
                _ssh_signing::_allowed_signers
                ;;
            "Remove signing config")
                log::break
                _ssh_signing::_remove
                ;;
        esac
    done
}

_ssh_signing::_setup() {
    # Select public key
    local pub_files=()
    local f
    for f in "$HOME"/.ssh/*.pub; do
        [[ -f "$f" ]] || continue
        pub_files+=("$(basename "$f")")
    done

    if [[ ${#pub_files[@]} -eq 0 ]]; then
        log::warn "No SSH public keys found. Generate a key first"
        return
    fi

    local selected
    selected="$(gum::choose \
        --header "Select signing key:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pub_files[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local key_base="${selected%.pub}"

    if [[ "$key_base" == id_ed25519_* ]]; then
        _ssh_signing::_setup_conditional "$selected" "$key_base"
    else
        _ssh_signing::_setup_global "$selected" "$key_base"
    fi
}

_ssh_signing::_setup_global() {
    local selected="$1"
    local key_base="$2"
    local key_path="~/.ssh/${key_base}"

    log::info "Configuring global commit signing"

    git config --global gpg.format ssh
    log::ok "gpg.format set to ssh"

    git config --global user.signingkey "$key_path"
    log::ok "Signing key: ${key_path}"

    git config --global commit.gpgsign true
    log::ok "Auto-sign commits enabled"

    # Configure allowed signers
    local git_email
    git_email="$(git config --global user.email 2>/dev/null || true)"
    if [[ -n "$git_email" ]]; then
        local key_content
        key_content="$(cat "$HOME/.ssh/${selected}")"
        printf '%s %s\n' "$git_email" "$key_content" > "$_SSH_ALLOWED_SIGNERS"
        log::ok "Allowed signers: ${git_email}"

        git config --global gpg.ssh.allowedSignersFile "~/.ssh/allowed_signers"
        log::ok "gpg.ssh.allowedSignersFile configured"
    fi

    _ssh_signing::_format_gitconfig
}

_ssh_signing::_setup_conditional() {
    local selected="$1"
    local key_base="$2"
    local key_path="~/.ssh/${key_base}"
    local suffix="${key_base#id_ed25519_}"
    local config_file="$HOME/.gitconfig-${suffix}"

    # Ask for gitdir pattern
    local gitdir
    gitdir="$(gum::input \
        --header "gitdir pattern for ${suffix}:" \
        --header.foreground "$HEX_LAVENDER" \
        --placeholder "~/dev/**")"

    if [[ -z "$gitdir" ]]; then
        log::warn "No gitdir provided, cancelled"
        return
    fi

    # Ask for name
    local git_name
    git_name="$(git config --global user.name 2>/dev/null || true)"
    local name
    name="$(gum::input \
        --header "Name for ${suffix}:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${git_name:-}" \
        --placeholder "Your Name")"

    if [[ -z "$name" ]]; then
        log::warn "No name provided, cancelled"
        return
    fi

    # Ask for email
    local git_email
    git_email="$(git config --global user.email 2>/dev/null || true)"
    local email
    email="$(gum::input \
        --header "Email for ${suffix}:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${git_email:-}" \
        --placeholder "your@email.com")"

    if [[ -z "$email" ]]; then
        log::warn "No email provided, cancelled"
        return
    fi

    log::info "Configuring conditional signing for ${suffix}"

    # Write conditional config file
    {
        printf '[user]\n'
        printf '\tname = %s\n' "$name"
        printf '\temail = %s\n' "$email"
        printf '\tsigningkey = %s\n' "$key_path"
    } > "$config_file"
    log::ok "Config written to ~/.gitconfig-${suffix}"

    # Add includeIf to main gitconfig
    git config --global "includeIf.gitdir:${gitdir}.path" "~/.gitconfig-${suffix}"
    log::ok "includeIf added for ${gitdir}"

    # Ensure global signing settings
    if ! _ssh_signing::has_format; then
        git config --global gpg.format ssh
        log::ok "gpg.format set to ssh"
    fi

    if ! _ssh_signing::has_autosign; then
        git config --global commit.gpgsign true
        log::ok "Auto-sign commits enabled"
    fi

    # Append to allowed signers
    local key_content
    key_content="$(cat "$HOME/.ssh/${selected}")"
    printf '%s %s\n' "$email" "$key_content" >> "$_SSH_ALLOWED_SIGNERS"
    log::ok "Added to allowed signers: ${email}"

    if ! git config --global gpg.ssh.allowedSignersFile &>/dev/null; then
        git config --global gpg.ssh.allowedSignersFile "~/.ssh/allowed_signers"
        log::ok "gpg.ssh.allowedSignersFile configured"
    fi

    _ssh_signing::_format_gitconfig
}

# Public API: setup signing for a specific key (called from keys.sh)
ssh_signing::setup_key() {
    local selected="$1"
    local key_base="${selected%.pub}"

    if [[ "$key_base" == id_ed25519_* ]]; then
        _ssh_signing::_setup_conditional "$selected" "$key_base"
    else
        _ssh_signing::_setup_global "$selected" "$key_base"
    fi
}

_ssh_signing::_allowed_signers() {
    local git_email
    git_email="$(git config --global user.email 2>/dev/null || true)"

    local email
    email="$(gum::input \
        --header "Email for allowed signers:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${git_email:-}" \
        --placeholder "your@email.com")"

    if [[ -z "$email" ]]; then
        log::warn "No email provided, cancelled"
        return
    fi

    # Select public key
    local pub_files=()
    local f
    for f in "$HOME"/.ssh/*.pub; do
        [[ -f "$f" ]] || continue
        pub_files+=("$(basename "$f")")
    done

    if [[ ${#pub_files[@]} -eq 0 ]]; then
        log::warn "No SSH public keys found. Generate a key first"
        return
    fi

    local selected
    selected="$(gum::choose \
        --header "Select key for allowed signers:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pub_files[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local key_content
    key_content="$(cat "$HOME/.ssh/${selected}")"

    log::info "Configuring allowed signers"

    printf '%s %s\n' "$email" "$key_content" >> "$_SSH_ALLOWED_SIGNERS"
    log::ok "Allowed signers written to ${_SSH_ALLOWED_SIGNERS}"

    git config --global gpg.ssh.allowedSignersFile "~/.ssh/allowed_signers"
    log::ok "gpg.ssh.allowedSignersFile configured"

    _ssh_signing::_format_gitconfig
}

_ssh_signing::_remove() {
    log::info "Removing commit signing configuration"

    git config --global --unset gpg.format || true
    git config --global --unset user.signingkey || true
    git config --global --unset commit.gpgsign || true
    git config --global --unset gpg.ssh.allowedSignersFile || true

    # Remove conditional configs
    local includes
    includes="$(git config --global --get-regexp 'includeIf\..*\.path' 2>/dev/null || true)"
    if [[ -n "$includes" ]]; then
        while IFS= read -r line; do
            local key val
            key="${line%% *}"
            val="${line#* }"
            git config --global --unset "$key" || true
            local expanded="${val/#\~/$HOME}"
            if [[ -f "$expanded" ]]; then
                rm "$expanded"
                log::ok "Removed ${val}"
            fi
        done <<< "$includes"
    fi

    log::ok "Signing configuration removed from git config"

    _ssh_signing::_format_gitconfig

    if [[ -f "$_SSH_ALLOWED_SIGNERS" ]]; then
        rm "$_SSH_ALLOWED_SIGNERS"
        log::ok "Allowed signers file removed"
    fi
}

# Ensure blank lines between sections in gitconfig
_ssh_signing::_format_gitconfig() {
    local gitconfig="$HOME/.gitconfig"
    [[ -f "$gitconfig" ]] || return 0
    local content
    content="$(awk 'NR>1 && /^\[/ && prev!="" {print ""} {prev=$0; print}' "$gitconfig")"
    printf '%s\n' "$content" > "$gitconfig"
}
