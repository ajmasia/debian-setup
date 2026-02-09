# Dotfiles management task (GNU Stow)

[[ -n "${_MOD_DOTFILES_LOADED:-}" ]] && return 0
_MOD_DOTFILES_LOADED=1

_DOTFILES_LABEL="Configure Dotfiles"
_DOTFILES_DESC="Clone and apply dotfiles via GNU Stow."

_DOTFILES_DIR="$HOME/.dotfiles"
_DOTFILES_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/debian-setup"
_DOTFILES_CONF="${_DOTFILES_CONF_DIR}/dotfiles.conf"

# ── Helpers ─────────────────────────────────────────────

_dotfiles::stow_installed() {
    command -v stow &>/dev/null
}

_dotfiles::repo_cloned() {
    [[ -d "${_DOTFILES_DIR}/.git" ]]
}

_dotfiles::saved_url() {
    if [[ -f "$_DOTFILES_CONF" ]]; then
        grep -oP '^DOTFILES_REPO=\K.*' "$_DOTFILES_CONF" 2>/dev/null || true
    fi
}

_dotfiles::save_url() {
    local url="$1"
    mkdir -p "$_DOTFILES_CONF_DIR"
    printf 'DOTFILES_REPO=%s\n' "$url" > "$_DOTFILES_CONF"
}

_dotfiles::list_packages() {
    local dir
    for dir in "${_DOTFILES_DIR}"/*/; do
        [[ -d "$dir" ]] || continue
        local name
        name="$(basename "$dir")"
        [[ "$name" == ".git" ]] && continue
        printf '%s\n' "$name"
    done
}

_dotfiles::is_stowed() {
    local pkg="$1"
    # Check if any symlink in $HOME points back to the package dir
    local src="${_DOTFILES_DIR}/${pkg}"
    local target
    for target in "$src"/.* "$src"/*; do
        [[ -e "$target" ]] || continue
        local name
        name="$(basename "$target")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        local home_path="$HOME/${name}"
        if [[ -L "$home_path" ]]; then
            local link_target
            link_target="$(readlink -f "$home_path")"
            if [[ "$link_target" == "${src}/"* || "$link_target" == "$target" ]]; then
                return 0
            fi
        fi
    done
    return 1
}

# ── Public API ──────────────────────────────────────────

dotfiles::check() {
    _dotfiles::stow_installed && _dotfiles::repo_cloned
}

dotfiles::status() {
    local issues=()
    _dotfiles::stow_installed || issues+=("stow not installed")
    _dotfiles::repo_cloned || issues+=("repo not cloned")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

# ── Wizard ──────────────────────────────────────────────

dotfiles::apply() {
    local choice

    while true; do
        local stow_ok=false repo_ok=false
        _dotfiles::stow_installed && stow_ok=true
        _dotfiles::repo_cloned && repo_ok=true

        ui::clear_content
        log::nav "Shell > Dotfiles"
        log::break

        log::info "Dotfiles (GNU Stow)"

        if $stow_ok; then
            log::ok "GNU Stow: installed"
        else
            log::warn "GNU Stow: not installed"
        fi

        if $repo_ok; then
            local url
            url="$(_dotfiles::saved_url)"
            log::ok "Repo: ${_DOTFILES_DIR}"
            [[ -n "$url" ]] && log::ok "Remote: ${url}"

            # Show packages summary
            local pkg total=0 stowed=0
            while IFS= read -r pkg; do
                total=$((total + 1))
                _dotfiles::is_stowed "$pkg" && stowed=$((stowed + 1))
            done < <(_dotfiles::list_packages)

            if [[ $total -gt 0 ]]; then
                if [[ $stowed -eq $total ]]; then
                    log::ok "Packages: ${stowed}/${total} applied"
                else
                    log::warn "Packages: ${stowed}/${total} applied"
                fi
            fi
        else
            log::warn "Repo: not cloned"
        fi

        log::break

        local options=()

        if ! $stow_ok; then
            options+=("Install GNU Stow")
        fi

        if ! $repo_ok; then
            options+=("Clone dotfiles repo")
        fi

        if $stow_ok && $repo_ok; then
            options+=("Show packages" "Apply all packages" "Select packages to apply" "Remove packages" "Update repo")
        fi

        options+=("Help" "Back" "Exit")

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
            "Install GNU Stow")
                log::break
                _dotfiles::install_stow
                ;;
            "Clone dotfiles repo")
                log::break
                _dotfiles::clone
                ;;
            "Show packages")
                log::break
                _dotfiles::show
                ;;
            "Apply all packages")
                log::break
                _dotfiles::apply_all
                ;;
            "Select packages to apply")
                log::break
                _dotfiles::select_apply
                ;;
            "Remove packages")
                log::break
                _dotfiles::select_remove
                ;;
            "Update repo")
                log::break
                _dotfiles::update
                ;;
            "Help")
                log::break
                _dotfiles::help
                ;;
        esac
    done
}

# ── Install Stow ───────────────────────────────────────

_dotfiles::install_stow() {
    log::info "Installing GNU Stow"
    ui::flush_input
    if sudo apt-get install -y stow </dev/tty; then
        hash -r
        log::ok "GNU Stow installed"
    else
        log::error "Failed to install GNU Stow"
    fi
}

# ── Clone ───────────────────────────────────────────────

_dotfiles::clone() {
    local url
    url="$(_dotfiles::saved_url)"

    local repo_url
    repo_url="$(gum::input \
        --header "Dotfiles repo URL (HTTPS or SSH):" \
        --header.foreground "$HEX_LAVENDER" \
        --value "${url:-}" \
        --placeholder "https://github.com/user/dotfiles.git")"

    if [[ -z "$repo_url" ]]; then
        log::warn "No URL provided, skipped"
        return
    fi

    log::info "Cloning to ${_DOTFILES_DIR}"
    if git clone "$repo_url" "$_DOTFILES_DIR"; then
        _dotfiles::save_url "$repo_url"
        log::ok "Dotfiles cloned"
    else
        log::error "Failed to clone repository"
    fi
}

# ── Show ────────────────────────────────────────────────

_dotfiles::show() {
    local pkg
    while IFS= read -r pkg; do
        if _dotfiles::is_stowed "$pkg"; then
            log::ok "${pkg} (applied)"
        else
            log::warn "${pkg} (not applied)"
        fi
    done < <(_dotfiles::list_packages)

    ui::return_or_exit
}

# ── Apply all ───────────────────────────────────────────

_dotfiles::apply_all() {
    local pkg count=0

    while IFS= read -r pkg; do
        if ! _dotfiles::is_stowed "$pkg"; then
            log::info "Applying ${pkg}"
            if stow -d "$_DOTFILES_DIR" -t "$HOME" "$pkg" 2>&1; then
                log::ok "${pkg} applied"
                count=$((count + 1))
            else
                log::error "Failed to apply ${pkg} (conflict?)"
            fi
        fi
    done < <(_dotfiles::list_packages)

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} package(s) applied"
    else
        log::ok "All packages already applied"
    fi
}

# ── Select apply ────────────────────────────────────────

_dotfiles::select_apply() {
    local pkg
    local pending_labels=()

    while IFS= read -r pkg; do
        if ! _dotfiles::is_stowed "$pkg"; then
            pending_labels+=("$pkg")
        fi
    done < <(_dotfiles::list_packages)

    if [[ ${#pending_labels[@]} -eq 0 ]]; then
        log::ok "All packages already applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select packages to apply:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local name count=0
    while IFS= read -r name; do
        log::info "Applying ${name}"
        if stow -d "$_DOTFILES_DIR" -t "$HOME" "$name" 2>&1; then
            log::ok "${name} applied"
            count=$((count + 1))
        else
            log::error "Failed to apply ${name} (conflict?)"
        fi
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} package(s) applied"
    fi
}

# ── Select remove ───────────────────────────────────────

_dotfiles::select_remove() {
    local pkg
    local applied_labels=()

    while IFS= read -r pkg; do
        if _dotfiles::is_stowed "$pkg"; then
            applied_labels+=("$pkg")
        fi
    done < <(_dotfiles::list_packages)

    if [[ ${#applied_labels[@]} -eq 0 ]]; then
        log::ok "No packages applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select packages to remove:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${applied_labels[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local name count=0
    while IFS= read -r name; do
        log::info "Removing ${name}"
        if stow -d "$_DOTFILES_DIR" -t "$HOME" -D "$name" 2>&1; then
            log::ok "${name} removed"
            count=$((count + 1))
        else
            log::error "Failed to remove ${name}"
        fi
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} package(s) removed"
    fi
}

# ── Update ──────────────────────────────────────────────

_dotfiles::update() {
    log::info "Pulling latest changes"
    if git -C "$_DOTFILES_DIR" pull --ff-only; then
        log::ok "Dotfiles updated"
    else
        log::error "Failed to update (local changes or diverged history?)"
    fi
}

# ── Help ────────────────────────────────────────────────

_dotfiles::help() {
    log::info "Dotfiles repo structure (GNU Stow)"
    log::break

    printf "%b" "${COLOR_OVERLAY1}"
    cat <<'HELP'
  Each top-level directory is a "package". Inside it, replicate
  the file structure relative to $HOME.

  dotfiles/
  ├── bash/
  │   ├── .bashrc
  │   └── .bash_profile
  ├── git/
  │   └── .gitconfig
  ├── starship/
  │   └── .config/
  │       └── starship.toml
  ├── alacritty/
  │   └── .config/
  │       └── alacritty/
  │           └── alacritty.toml
  ├── tmux/
  │   └── .tmux.conf
  └── vim/
      └── .vimrc

  "stow bash" creates:  ~/.bashrc -> ~/.dotfiles/bash/.bashrc
  "stow -D bash" removes the symlinks.

  Usage without debian-setup (works on any system):

    cd ~/.dotfiles
    stow bash git starship    # apply packages
    stow -D bash              # remove a package
    stow -R bash              # re-apply (after editing)

  Tips:
  - One directory per tool/app, keeps things modular
  - The repo is fully portable across distros
  - Nested .config/ dirs work naturally
  - stow detects conflicts before creating symlinks
HELP
    printf "%b" "${COLOR_RESET}"

    ui::return_or_exit
}
