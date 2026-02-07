# SSH config task for git services

[[ -n "${_MOD_SSH_CONFIG_LOADED:-}" ]] && return 0
_MOD_SSH_CONFIG_LOADED=1

_SSH_CONFIG_LABEL="Configure SSH config"
_SSH_CONFIG_DESC="Manage ~/.ssh/config entries for GitHub, GitLab, and custom servers."

_SSH_CONFIG_FILE="$HOME/.ssh/config"

_ssh_config::has_github() {
    [[ -f "$_SSH_CONFIG_FILE" ]] && grep -q '^# GitHub$' "$_SSH_CONFIG_FILE" 2>/dev/null
}

_ssh_config::has_gitlab() {
    [[ -f "$_SSH_CONFIG_FILE" ]] && grep -q '^# GitLab$' "$_SSH_CONFIG_FILE" 2>/dev/null
}

_ssh_config::_list_custom() {
    [[ -f "$_SSH_CONFIG_FILE" ]] || return
    awk '/^# /{name=substr($0,3); next} name && /^Host /{print name} {name=""}' \
        "$_SSH_CONFIG_FILE" 2>/dev/null | grep -vE '^(GitHub|GitLab)$' || true
}

ssh_config::check() {
    _ssh_config::has_github && _ssh_config::has_gitlab
}

ssh_config::status() {
    local issues=()
    _ssh_config::has_github || issues+=("no GitHub")
    _ssh_config::has_gitlab || issues+=("no GitLab")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

ssh_config::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "OpenSSH server > Configure SSH config"
        log::break

        log::info "Current SSH config entries"

        if _ssh_config::has_github; then
            if _ssh_config::_quick_test "github.com"; then
                log::ok "GitHub: connected"
            else
                log::warn "GitHub: configured (connection failed)"
            fi
        else
            log::warn "GitHub: not configured"
        fi

        if _ssh_config::has_gitlab; then
            if _ssh_config::_quick_test "gitlab.com"; then
                log::ok "GitLab: connected"
            else
                log::warn "GitLab: configured (connection failed)"
            fi
        else
            log::warn "GitLab: not configured"
        fi

        # Custom servers
        local custom_list
        custom_list="$(_ssh_config::_list_custom)"
        if [[ -n "$custom_list" ]]; then
            local srv
            while IFS= read -r srv; do
                if _ssh_config::_quick_test "$srv"; then
                    log::ok "${srv}: connected"
                else
                    log::warn "${srv}: configured (connection failed)"
                fi
            done <<< "$custom_list"
        fi

        log::break

        local options=()

        if _ssh_config::has_github; then
            options+=("Remove GitHub")
        else
            options+=("Add GitHub")
        fi

        if _ssh_config::has_gitlab; then
            options+=("Remove GitLab")
        else
            options+=("Add GitLab")
        fi

        options+=("Add server")

        if [[ -n "$custom_list" ]]; then
            local srv
            while IFS= read -r srv; do
                options+=("Remove ${srv}")
            done <<< "$custom_list"
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
            "Add GitHub")
                log::break
                _ssh_config::_setup_service "GitHub" "github.com" "github.com" "22"
                ;;
            "Add GitLab")
                log::break
                _ssh_config::_setup_service "GitLab" "gitlab.com" "gitlab.com" "22"
                ;;
            "Add server")
                log::break
                _ssh_config::_setup_manual
                ;;
            "Remove GitHub")
                log::break
                _ssh_config::_remove_entry "GitHub"
                ;;
            "Remove GitLab")
                log::break
                _ssh_config::_remove_entry "GitLab"
                ;;
            Remove\ *)
                log::break
                _ssh_config::_remove_entry "${choice#Remove }"
                ;;
        esac
    done
}

_ssh_config::_select_key() {
    local pub_files=()
    local f
    for f in "$HOME"/.ssh/*.pub; do
        [[ -f "$f" ]] || continue
        pub_files+=("$(basename "$f")")
    done

    if [[ ${#pub_files[@]} -eq 0 ]]; then
        log::warn "No SSH public keys found. Generate a key first"
        return 1
    fi

    local selected
    selected="$(gum::choose \
        --header "Select SSH key to use:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pub_files[@]}")"

    if [[ -z "$selected" ]]; then
        return 1
    fi

    # Return private key path (remove .pub suffix)
    printf '%s' "$HOME/.ssh/${selected%.pub}"
}

_ssh_config::_setup_service() {
    local service="$1"
    local host="$2"
    local hostname="$3"
    local port="$4"

    local key_path
    key_path="$(_ssh_config::_select_key)" || return 0

    _ssh_config::_write_entry "$service" "$host" "$hostname" "$port" "$key_path" "git"
    _ssh_config::_test_host "$host"
}

_ssh_config::_setup_manual() {
    local host hostname port user key_path

    host="$(gum::input \
        --header "Host (alias):" \
        --header.foreground "$HEX_LAVENDER" \
        --placeholder "git.qwertee.link")"

    if [[ -z "$host" ]]; then
        log::warn "No host provided, cancelled"
        return
    fi

    # Check if Host already exists (marker or Host line)
    local host_exists=false
    grep -q "^# ${host}$" "$_SSH_CONFIG_FILE" 2>/dev/null && host_exists=true
    grep -q "^Host ${host}$" "$_SSH_CONFIG_FILE" 2>/dev/null && host_exists=true
    if $host_exists; then
        log::warn "Host '${host}' already configured"
        local action
        action="$(gum::choose \
            --header "What to do?" \
            "Replace existing" "Cancel")"
        [[ "$action" != "Replace existing" ]] && return
    fi

    hostname="$(gum::input \
        --header "HostName (hostname or IP):" \
        --header.foreground "$HEX_LAVENDER" \
        --placeholder "192.179.4.69")"

    if [[ -z "$hostname" ]]; then
        log::warn "No hostname provided, cancelled"
        return
    fi

    # Check if HostName already used by another entry
    local hn_exists=false
    grep -q "HostName ${hostname}$" "$_SSH_CONFIG_FILE" 2>/dev/null && hn_exists=true
    if $hn_exists; then
        local existing
        existing="$(awk -v hn="$hostname" \
            '/^# /{name=substr($0,3)} /^[[:space:]]*HostName / && $2==hn {print name; exit}' \
            "$_SSH_CONFIG_FILE" 2>/dev/null || true)"
    fi
    if $hn_exists && [[ "${existing:-}" != "$host" ]]; then
        log::warn "HostName '${hostname}' already used by '${existing}'"
        local action
        action="$(gum::choose \
            --header "Continue anyway?" \
            "Continue" "Cancel")"
        [[ "$action" != "Continue" ]] && return
    fi

    port="$(gum::input \
        --header "Port (default 22):" \
        --header.foreground "$HEX_LAVENDER" \
        --value "22" \
        --placeholder "22")"
    port="${port:-22}"

    user="$(gum::input \
        --header "User:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "git" \
        --placeholder "git")"
    user="${user:-git}"

    key_path="$(_ssh_config::_select_key)" || return 0

    _ssh_config::_write_entry "$host" "$host" "$hostname" "$port" "$key_path" "$user"
    _ssh_config::_test_host "$host"
}

_ssh_config::_write_entry() {
    local service="$1"
    local host="$2"
    local hostname="$3"
    local port="$4"
    local key_path="$5"
    local user="${6:-git}"

    # Remove existing entry if present
    if grep -q "^# ${service}$" "$_SSH_CONFIG_FILE" 2>/dev/null; then
        sed -i "/^# ${service}$/,/^$/d" "$_SSH_CONFIG_FILE"
        log::info "Replaced existing ${service} entry"
    fi

    # Ensure config file and directory exist
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$_SSH_CONFIG_FILE"
    chmod 600 "$_SSH_CONFIG_FILE"

    log::info "Adding ${service} to SSH config"

    {
        printf '\n# %s\n' "$service"
        printf 'Host %s\n' "$host"
        printf '    HostName %s\n' "$hostname"
        printf '    User %s\n' "$user"
        printf '    IdentityFile %s\n' "$key_path"
        if [[ "$port" != "22" ]]; then
            printf '    Port %s\n' "$port"
        fi
    } >> "$_SSH_CONFIG_FILE"

    log::ok "${service} added to ${_SSH_CONFIG_FILE}"
}

_ssh_config::_remove_entry() {
    local service="$1"

    log::info "Removing ${service} from SSH config"
    sed -i "/^# ${service}$/,/^$/d" "$_SSH_CONFIG_FILE"
    log::ok "${service} removed from ${_SSH_CONFIG_FILE}"
}

_ssh_config::_quick_test() {
    local host="$1"
    local output
    output="$(ssh -T -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new "${host}" 2>&1 || true)"
    [[ "$output" == *"successfully authenticated"* ]] || [[ "$output" == *"Welcome"* ]] || [[ "$output" == *"welcome"* ]]
}

_ssh_config::_test_host() {
    local host="$1"

    log::break
    log::info "Testing connection to ${host}"

    local output
    output="$(ssh -T -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${host}" 2>&1 || true)"

    if [[ "$output" == *"successfully authenticated"* ]] || [[ "$output" == *"Welcome"* ]] || [[ "$output" == *"welcome"* ]]; then
        log::ok "${host}: connection OK"
    else
        log::warn "${host}: connection failed"
        [[ -n "$output" ]] && log::warn "${output}"
    fi

    ui::return_or_exit
}
