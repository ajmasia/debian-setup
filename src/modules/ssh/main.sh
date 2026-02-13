# SSH module

[[ -n "${_MOD_SSH_LOADED:-}" ]] && return 0
_MOD_SSH_LOADED=1

# Task registry: "label|desc_var|check_fn|apply_fn|status_fn"
_SSH_TASKS=(
    "${_SSH_SERVER_LABEL}|_SSH_SERVER_DESC|ssh_server::check|ssh_server::apply|ssh_server::status"
    "${_SSH_ACCESS_LABEL}|_SSH_ACCESS_DESC|ssh_access::check|ssh_access::apply|ssh_access::status"
    "${_SSH_KEYS_LABEL}|_SSH_KEYS_DESC|ssh_keys::check|ssh_keys::apply|ssh_keys::status"
    "${_SSH_CONFIG_LABEL}|_SSH_CONFIG_DESC|ssh_config::check|ssh_config::apply|ssh_config::status"
    "${_SSH_SIGNING_LABEL}|_SSH_SIGNING_DESC|ssh_signing::check|ssh_signing::apply|ssh_signing::status"
)

ssh::log_status() {
    local task label desc_var check_fn apply_fn status_fn
    _log::to_file "info" "SSH tasks status"
    for task in "${_SSH_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if "$check_fn"; then
            _log::to_file "ok" "${label}"
        else
            local detail
            detail="$($status_fn)"
            _log::to_file "warn" "${label} (${detail})"
        fi
    done
}

ssh::has_pending() {
    local task label desc_var check_fn apply_fn status_fn
    for task in "${_SSH_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        if ! "$check_fn"; then
            return 0
        fi
    done
    return 1
}

