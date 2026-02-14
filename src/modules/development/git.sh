# Git configuration task

[[ -n "${_MOD_GIT_CONFIG_LOADED:-}" ]] && return 0
_MOD_GIT_CONFIG_LOADED=1

_GIT_CONFIG_LABEL="Configure Git"
_GIT_CONFIG_DESC="Install git and configure global/local settings."

_GIT_CONFIG_HOOKS_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/git/hooks"
_GIT_CONFIG_PRECOMMIT="${_GIT_CONFIG_HOOKS_DIR}/pre-commit"
_GIT_CONFIG_DEFAULT_MAX_SIZE="5"

_git_config::is_installed() {
    dpkg -l git 2>/dev/null | grep -q '^ii'
}

_git_config::has_name() {
    local val
    val="$(git config --global user.name 2>/dev/null || true)"
    [[ -n "$val" ]]
}

_git_config::has_email() {
    local val
    val="$(git config --global user.email 2>/dev/null || true)"
    [[ -n "$val" ]]
}

_git_config::has_default_branch() {
    local val
    val="$(git config --global init.defaultBranch 2>/dev/null || true)"
    [[ -n "$val" ]]
}

_git_config::has_hook() {
    [[ -x "$_GIT_CONFIG_PRECOMMIT" ]]
}

# Ensure blank lines between sections in gitconfig
_git_config::_format_gitconfig() {
    local gitconfig="$HOME/.gitconfig"
    [[ -f "$gitconfig" ]] || return 0
    local content
    content="$(awk 'NR>1 && /^\[/ && prev!="" {print ""} {prev=$0; print}' "$gitconfig")"
    printf '%s\n' "$content" > "$gitconfig"
}

git_config::check() {
    _git_config::is_installed || return 1
    _git_config::has_name || return 1
    _git_config::has_email || return 1
    _git_config::has_default_branch || return 1
    return 0
}

git_config::status() {
    local issues=()
    _git_config::is_installed || issues+=("not installed")
    if _git_config::is_installed; then
        _git_config::has_name || issues+=("user.name missing")
        _git_config::has_email || issues+=("user.email missing")
        _git_config::has_default_branch || issues+=("init.defaultBranch missing")
    fi
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

git_config::apply() {
    local choice

    while true; do
        local installed=false
        _git_config::is_installed && installed=true

        ui::clear_content
        log::nav "Development > Tools > Git"
        log::break

        log::info "Git Configuration"

        if $installed; then
            local version
            version="$(git --version 2>/dev/null || true)"
            log::ok "Git: ${version}"
            log::break

            local val
            val="$(git config --global user.name 2>/dev/null || true)"
            if [[ -n "$val" ]]; then
                log::ok "user.name: ${val}"
            else
                log::warn "user.name: not set"
            fi

            val="$(git config --global user.email 2>/dev/null || true)"
            if [[ -n "$val" ]]; then
                log::ok "user.email: ${val}"
            else
                log::warn "user.email: not set"
            fi

            val="$(git config --global init.defaultBranch 2>/dev/null || true)"
            if [[ -n "$val" ]]; then
                log::ok "init.defaultBranch: ${val}"
            else
                log::warn "init.defaultBranch: not set"
            fi
            log::break

            val="$(git config --global pull.rebase 2>/dev/null || true)"
            [[ -n "$val" ]] && log::ok "pull.rebase: ${val}"

            val="$(git config --global push.autoSetupRemote 2>/dev/null || true)"
            [[ -n "$val" ]] && log::ok "push.autoSetupRemote: ${val}"

            val="$(git config --global fetch.prune 2>/dev/null || true)"
            [[ -n "$val" ]] && log::ok "fetch.prune: ${val}"

            val="$(git config --global rerere.enabled 2>/dev/null || true)"
            [[ -n "$val" ]] && log::ok "rerere.enabled: ${val}"

            val="$(git config --global diff.colorMoved 2>/dev/null || true)"
            [[ -n "$val" ]] && log::ok "diff.colorMoved: ${val}"
            log::break

            if _git_config::has_hook; then
                local max
                max="$(git config --global debian-setup.maxFileSize 2>/dev/null || true)"
                log::ok "Large file guard: active (${max:-$_GIT_CONFIG_DEFAULT_MAX_SIZE} MB)"
            fi
        else
            log::warn "Git (not installed)"
        fi

        log::break

        local options=()

        if $installed; then
            options+=("Configure Global Settings")
            options+=("Configure Local Repository")
            if _git_config::has_hook; then
                options+=("Update Large File Guard")
                options+=("Remove Large File Guard")
            else
                options+=("Setup Large File Guard")
            fi
            options+=("Remove Git")
        else
            options+=("Install Git")
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
            "Install Git")
                log::break
                _git_config::install
                ;;
            "Remove Git")
                log::break
                _git_config::remove
                ;;
            "Configure Global Settings")
                log::break
                _git_config::configure_global
                ;;
            "Configure Local Repository")
                log::break
                _git_config::configure_local
                ;;
            "Setup Large File Guard"|"Update Large File Guard")
                log::break
                _git_config::setup_hooks
                ;;
            "Remove Large File Guard")
                log::break
                _git_config::remove_hooks
                ;;
        esac
    done
}

_git_config::install() {
    log::info "Installing Git"
    ui::flush_input
    if sudo apt-get install -y git </dev/tty; then
        hash -r
        log::ok "Git installed"
    else
        log::error "Failed to install Git"
    fi
}

_git_config::remove() {
    log::info "Removing Git"
    ui::flush_input
    if sudo apt-get remove -y git </dev/tty; then
        hash -r
        log::ok "Git removed"
    else
        log::error "Failed to remove Git"
    fi
}

_git_config::configure_global() {
    log::info "Configure global git settings"
    log::break

    # 1. user.name (required)
    local current_name
    current_name="$(git config --global user.name 2>/dev/null || true)"
    local name
    name="$(gum::input \
        --header "user.name:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${current_name:-}" \
        --placeholder "Your Name")"
    if [[ -z "$name" ]]; then
        log::warn "No name provided, cancelled"
        return
    fi
    git config --global user.name "$name"
    log::ok "user.name: ${name}"

    # 2. user.email (required)
    local current_email
    current_email="$(git config --global user.email 2>/dev/null || true)"
    local email
    email="$(gum::input \
        --header "user.email:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${current_email:-}" \
        --placeholder "your@email.com")"
    if [[ -z "$email" ]]; then
        log::warn "No email provided, cancelled"
        return
    fi
    git config --global user.email "$email"
    log::ok "user.email: ${email}"

    # 3. init.defaultBranch (required)
    local current_branch
    current_branch="$(git config --global init.defaultBranch 2>/dev/null || true)"
    local branch
    branch="$(gum::input \
        --header "init.defaultBranch:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${current_branch:-main}" \
        --placeholder "main")"
    if [[ -z "$branch" ]]; then
        log::warn "No branch provided, cancelled"
        return
    fi
    git config --global init.defaultBranch "$branch"
    log::ok "init.defaultBranch: ${branch}"

    # 4. pull.rebase (optional)
    local pull_rebase
    pull_rebase="$(gum::choose \
        --header "pull.rebase (rebase instead of merge on pull):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "true" "false" "Skip")"
    if [[ -n "$pull_rebase" && "$pull_rebase" != "Skip" ]]; then
        git config --global pull.rebase "$pull_rebase"
        log::ok "pull.rebase: ${pull_rebase}"
    fi

    # 5. push.autoSetupRemote (optional)
    local push_auto
    push_auto="$(gum::choose \
        --header "push.autoSetupRemote (auto-track remote on first push):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "true" "false" "Skip")"
    if [[ -n "$push_auto" && "$push_auto" != "Skip" ]]; then
        git config --global push.autoSetupRemote "$push_auto"
        log::ok "push.autoSetupRemote: ${push_auto}"
    fi

    # 6. fetch.prune (optional)
    local fetch_prune
    fetch_prune="$(gum::choose \
        --header "fetch.prune (remove stale remote branches on fetch):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "true" "false" "Skip")"
    if [[ -n "$fetch_prune" && "$fetch_prune" != "Skip" ]]; then
        git config --global fetch.prune "$fetch_prune"
        log::ok "fetch.prune: ${fetch_prune}"
    fi

    # 7. rerere.enabled (optional)
    local rerere
    rerere="$(gum::choose \
        --header "rerere.enabled (auto-resolve repeated merge conflicts):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "true" "false" "Skip")"
    if [[ -n "$rerere" && "$rerere" != "Skip" ]]; then
        git config --global rerere.enabled "$rerere"
        log::ok "rerere.enabled: ${rerere}"
    fi

    # 8. diff.colorMoved (optional)
    local color_moved
    color_moved="$(gum::choose \
        --header "diff.colorMoved (highlight moved lines in diffs):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "zebra" "default" "dimmed-delta" "Skip")"
    if [[ -n "$color_moved" && "$color_moved" != "Skip" ]]; then
        git config --global diff.colorMoved "$color_moved"
        log::ok "diff.colorMoved: ${color_moved}"
    fi

    _git_config::_format_gitconfig

    log::break
    log::ok "Global settings configured"
}

_git_config::configure_local() {
    log::info "Configure local repository settings"
    log::break

    # 1. Ask for repo path
    local repo_path
    repo_path="$(gum::input \
        --header "Repository path:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "$(pwd)" \
        --placeholder "/path/to/repo")"

    if [[ -z "$repo_path" ]]; then
        log::warn "No path provided, cancelled"
        return
    fi

    # Expand ~
    repo_path="${repo_path/#\~/$HOME}"

    # Validate .git exists
    if [[ ! -d "${repo_path}/.git" ]]; then
        log::error "Not a git repository: ${repo_path}"
        return
    fi

    log::ok "Repository: ${repo_path}"
    log::break

    # Show current local config
    local local_name local_email
    local_name="$(git -C "$repo_path" config --local user.name 2>/dev/null || true)"
    local_email="$(git -C "$repo_path" config --local user.email 2>/dev/null || true)"

    local global_name global_email
    global_name="$(git config --global user.name 2>/dev/null || true)"
    global_email="$(git config --global user.email 2>/dev/null || true)"

    if [[ -n "$local_name" ]]; then
        log::ok "Local user.name: ${local_name}"
    else
        log::info "Local user.name: not set (global: ${global_name:-none})"
    fi

    if [[ -n "$local_email" ]]; then
        log::ok "Local user.email: ${local_email}"
    else
        log::info "Local user.email: not set (global: ${global_email:-none})"
    fi

    log::break

    # 3. user.name
    local name
    name="$(gum::input \
        --header "Local user.name (empty = use global):" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${local_name:-}" \
        --placeholder "${global_name:-Your Name}")"

    if [[ -n "$name" ]]; then
        git -C "$repo_path" config --local user.name "$name"
        log::ok "Local user.name: ${name}"
    elif [[ -n "$local_name" ]]; then
        git -C "$repo_path" config --local --unset user.name || true
        log::ok "Local user.name cleared (using global)"
    fi

    # 4. user.email
    local email
    email="$(gum::input \
        --header "Local user.email (empty = use global):" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${local_email:-}" \
        --placeholder "${global_email:-your@email.com}")"

    if [[ -n "$email" ]]; then
        git -C "$repo_path" config --local user.email "$email"
        log::ok "Local user.email: ${email}"
    elif [[ -n "$local_email" ]]; then
        git -C "$repo_path" config --local --unset user.email || true
        log::ok "Local user.email cleared (using global)"
    fi

    log::break
    log::ok "Local settings configured"
}

_git_config::setup_hooks() {
    log::info "Large File Guard (pre-commit hook)"
    log::break
    log::warn "This sets core.hooksPath globally, which overrides per-repo .git/hooks/"
    log::break

    local confirm
    confirm="$(gum::choose \
        --header "Continue?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$confirm" != "Yes" ]]; then
        log::warn "Cancelled"
        return
    fi

    local current_max
    current_max="$(git config --global debian-setup.maxFileSize 2>/dev/null || true)"
    local max_size
    max_size="$(gum::input \
        --header "Max file size in MB:" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${current_max:-$_GIT_CONFIG_DEFAULT_MAX_SIZE}" \
        --placeholder "5")"

    if [[ -z "$max_size" ]]; then
        log::warn "No size provided, cancelled"
        return
    fi

    # Validate numeric
    if ! [[ "$max_size" =~ ^[0-9]+$ ]]; then
        log::error "Invalid number: ${max_size}"
        return
    fi

    local max_bytes=$((max_size * 1048576))

    # Create hooks directory
    mkdir -p "$_GIT_CONFIG_HOOKS_DIR"

    # Write pre-commit hook
    cat > "$_GIT_CONFIG_PRECOMMIT" <<'HOOK_EOF'
#!/usr/bin/env bash
# debian-setup: large file guard
# Prevents committing files larger than the configured limit.
# Bypass with: git commit --no-verify

MAX_BYTES=__MAX_BYTES__
MAX_MB=__MAX_MB__

while IFS= read -r -d '' file; do
    size="$(wc -c < "$file")"
    if [[ "$size" -gt "$MAX_BYTES" ]]; then
        printf '\033[31mBlocked:\033[0m %s is %s bytes (limit: %s MB)\n' "$file" "$size" "$MAX_MB" >&2
        printf 'Use \033[33mgit commit --no-verify\033[0m to bypass.\n' >&2
        exit 1
    fi
done < <(git diff --cached --name-only --diff-filter=d -z)
HOOK_EOF

    # Replace placeholders
    sed -i "s/__MAX_BYTES__/${max_bytes}/" "$_GIT_CONFIG_PRECOMMIT"
    sed -i "s/__MAX_MB__/${max_size}/" "$_GIT_CONFIG_PRECOMMIT"

    chmod +x "$_GIT_CONFIG_PRECOMMIT"

    # Store max size for display
    git config --global debian-setup.maxFileSize "$max_size"

    # Set global hooks path
    git config --global core.hooksPath "$_GIT_CONFIG_HOOKS_DIR"

    log::ok "Pre-commit hook written to ${_GIT_CONFIG_PRECOMMIT}"
    log::ok "core.hooksPath set to ${_GIT_CONFIG_HOOKS_DIR}"
    log::ok "Max file size: ${max_size} MB"

    _git_config::_format_gitconfig
}

_git_config::remove_hooks() {
    log::info "Removing large file guard"

    # Only unset core.hooksPath if it points to our dir
    local current_path
    current_path="$(git config --global core.hooksPath 2>/dev/null || true)"
    if [[ "$current_path" == "$_GIT_CONFIG_HOOKS_DIR" ]]; then
        git config --global --unset core.hooksPath || true
        log::ok "core.hooksPath unset"
    fi

    if [[ -f "$_GIT_CONFIG_PRECOMMIT" ]]; then
        rm "$_GIT_CONFIG_PRECOMMIT"
        log::ok "Pre-commit hook removed"
    fi

    git config --global --unset debian-setup.maxFileSize || true

    _git_config::_format_gitconfig

    log::ok "Large file guard removed"
}
