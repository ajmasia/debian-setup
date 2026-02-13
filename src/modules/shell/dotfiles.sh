# Dotfiles management task (GNU Stow)

[[ -n "${_MOD_DOTFILES_LOADED:-}" ]] && return 0
_MOD_DOTFILES_LOADED=1

_DOTFILES_LABEL="Configure Dotfiles"
_DOTFILES_DESC="Clone and apply dotfiles via GNU Stow."

_DOTFILES_DIR="$HOME/.dotfiles"
_DOTFILES_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/debian-setup"
_DOTFILES_CONF="${_DOTFILES_CONF_DIR}/dotfiles.conf"

# Mapping: src_prefix:target_dir
# stow derives: -d DOTFILES_DIR/$(dirname prefix) -t target $(basename prefix)
_DOTFILES_MAP=(
    "home:${HOME}"
    "config:${HOME}/.config"
    "local/bin:${HOME}/.local/bin"
    "local/share/completions:${HOME}/.local/share/bash-completion/completions"
)

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

_dotfiles::list_items() {
    local mapping src_prefix
    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        local src_dir="${_DOTFILES_DIR}/${src_prefix}"
        [[ -d "$src_dir" ]] || continue
        local entry
        for entry in "$src_dir"/* "$src_dir"/.*; do
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            [[ "$name" == "." || "$name" == ".." ]] && continue
            printf '%s\n' "${src_prefix}/${name}"
        done
    done
}

_dotfiles::resolve_target() {
    local item="$1"
    local mapping src_prefix target_prefix
    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        target_prefix="${mapping#*:}"
        if [[ "$item" == "${src_prefix}/"* ]]; then
            local rel="${item#"${src_prefix}/"}"
            printf '%s' "${target_prefix}/${rel}"
            return 0
        fi
    done
    return 1
}

_dotfiles::is_linked() {
    local item="$1"
    local target
    target="$(_dotfiles::resolve_target "$item")" || return 1
    [[ -L "$target" ]] || return 1
    local link_dest
    link_dest="$(readlink -f "$target")"
    local source_path
    source_path="$(readlink -f "${_DOTFILES_DIR}/${item}")"
    [[ "$link_dest" == "$source_path" ]]
}

_dotfiles::group_has_items() {
    local src_prefix="$1"
    local src_dir="${_DOTFILES_DIR}/${src_prefix}"
    [[ -d "$src_dir" ]] || return 1
    local entry name
    for entry in "$src_dir"/* "$src_dir"/.*; do
        [[ -e "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        return 0
    done
    return 1
}

_dotfiles::group_applied() {
    local src_prefix="$1"
    local src_dir="${_DOTFILES_DIR}/${src_prefix}"
    [[ -d "$src_dir" ]] || return 1
    local entry name has_items=false
    for entry in "$src_dir"/* "$src_dir"/.*; do
        [[ -e "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        has_items=true
        _dotfiles::is_linked "${src_prefix}/${name}" || return 1
    done
    $has_items
}

_dotfiles::group_has_pending() {
    local src_prefix="$1"
    local src_dir="${_DOTFILES_DIR}/${src_prefix}"
    [[ -d "$src_dir" ]] || return 1
    local entry name
    for entry in "$src_dir"/* "$src_dir"/.*; do
        [[ -e "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        _dotfiles::is_linked "${src_prefix}/${name}" || return 0
    done
    return 1
}

_dotfiles::group_has_applied() {
    local src_prefix="$1"
    local src_dir="${_DOTFILES_DIR}/${src_prefix}"
    [[ -d "$src_dir" ]] || return 1
    local entry name
    for entry in "$src_dir"/* "$src_dir"/.*; do
        [[ -e "$entry" ]] || continue
        name="$(basename "$entry")"
        [[ "$name" == "." || "$name" == ".." ]] && continue
        _dotfiles::is_linked "${src_prefix}/${name}" && return 0
    done
    return 1
}

# ── Stow operations ────────────────────────────────────

_dotfiles::stow_apply() {
    local src_prefix="$1" target="$2"
    local parent package stow_dir
    parent="$(dirname "$src_prefix")"
    package="$(basename "$src_prefix")"
    if [[ "$parent" == "." ]]; then
        stow_dir="$_DOTFILES_DIR"
    else
        stow_dir="${_DOTFILES_DIR}/${parent}"
    fi
    mkdir -p "$target"
    stow -d "$stow_dir" -t "$target" "$package" 2>&1
}

_dotfiles::stow_remove() {
    local src_prefix="$1" target="$2"
    local parent package stow_dir
    parent="$(dirname "$src_prefix")"
    package="$(basename "$src_prefix")"
    if [[ "$parent" == "." ]]; then
        stow_dir="$_DOTFILES_DIR"
    else
        stow_dir="${_DOTFILES_DIR}/${parent}"
    fi
    stow -d "$stow_dir" -t "$target" -D "$package" 2>&1
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

            # Show items summary
            local item total=0 linked=0
            while IFS= read -r item; do
                total=$((total + 1))
                _dotfiles::is_linked "$item" && linked=$((linked + 1))
            done < <(_dotfiles::list_items)

            if [[ $total -gt 0 ]]; then
                if [[ $linked -eq $total ]]; then
                    log::ok "Items: ${linked}/${total} applied"
                else
                    log::warn "Items: ${linked}/${total} applied"
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
            options+=("Show items" "Apply all" "Select to apply" "Select to remove" "Update repo")
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
            "Show items")
                log::break
                _dotfiles::show
                ;;
            "Apply all")
                log::break
                _dotfiles::apply_all
                ;;
            "Select to apply")
                log::break
                _dotfiles::select_apply
                ;;
            "Select to remove")
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
    local mapping src_prefix
    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        _dotfiles::group_has_items "$src_prefix" || continue

        local group_status
        if _dotfiles::group_applied "$src_prefix"; then
            group_status="applied"
        elif _dotfiles::group_has_applied "$src_prefix"; then
            group_status="partial"
        else
            group_status="not applied"
        fi

        printf "\n%b── %s (%s) ──%b\n" "${COLOR_OVERLAY1}" "$src_prefix" "$group_status" "${COLOR_RESET}"

        local src_dir="${_DOTFILES_DIR}/${src_prefix}"
        local entry name
        for entry in "$src_dir"/* "$src_dir"/.*; do
            [[ -e "$entry" ]] || continue
            name="$(basename "$entry")"
            [[ "$name" == "." || "$name" == ".." ]] && continue
            local item="${src_prefix}/${name}"
            if _dotfiles::is_linked "$item"; then
                log::ok "  ${name}"
            else
                log::warn "  ${name}"
            fi
        done
    done

    log::break
    ui::return_or_exit
}

# ── Apply all ───────────────────────────────────────────

_dotfiles::apply_all() {
    local mapping src_prefix target_prefix count=0

    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        target_prefix="${mapping#*:}"
        _dotfiles::group_has_items "$src_prefix" || continue
        _dotfiles::group_applied "$src_prefix" && continue

        log::info "Applying ${src_prefix}"
        if _dotfiles::stow_apply "$src_prefix" "$target_prefix"; then
            log::ok "${src_prefix} applied"
            count=$((count + 1))
        else
            log::error "Failed to apply ${src_prefix} (conflict?)"
        fi
    done

    log::break
    if [[ $count -gt 0 ]]; then
        log::ok "${count} group(s) applied"
    else
        log::ok "All groups already applied"
    fi
}

# ── Select apply ────────────────────────────────────────

_dotfiles::select_apply() {
    local mapping src_prefix
    local pending=()

    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        _dotfiles::group_has_items "$src_prefix" || continue
        _dotfiles::group_has_pending "$src_prefix" && pending+=("$src_prefix")
    done

    if [[ ${#pending[@]} -eq 0 ]]; then
        log::ok "All groups already applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select groups to apply:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local group count=0
    while IFS= read -r group; do
        local target_prefix=""
        for mapping in "${_DOTFILES_MAP[@]}"; do
            src_prefix="${mapping%%:*}"
            if [[ "$src_prefix" == "$group" ]]; then
                target_prefix="${mapping#*:}"
                break
            fi
        done
        [[ -n "$target_prefix" ]] || continue

        log::info "Applying ${group}"
        if _dotfiles::stow_apply "$group" "$target_prefix"; then
            log::ok "${group} applied"
            count=$((count + 1))
        else
            log::error "Failed to apply ${group} (conflict?)"
        fi
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} group(s) applied"
    fi
}

# ── Select remove ───────────────────────────────────────

_dotfiles::select_remove() {
    local mapping src_prefix
    local applied=()

    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        _dotfiles::group_has_items "$src_prefix" || continue
        _dotfiles::group_has_applied "$src_prefix" && applied+=("$src_prefix")
    done

    if [[ ${#applied[@]} -eq 0 ]]; then
        log::ok "No groups applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select groups to remove:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${applied[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local group count=0
    while IFS= read -r group; do
        local target_prefix=""
        for mapping in "${_DOTFILES_MAP[@]}"; do
            src_prefix="${mapping%%:*}"
            if [[ "$src_prefix" == "$group" ]]; then
                target_prefix="${mapping#*:}"
                break
            fi
        done
        [[ -n "$target_prefix" ]] || continue

        log::info "Removing ${group}"
        if _dotfiles::stow_remove "$group" "$target_prefix"; then
            log::ok "${group} removed"
            count=$((count + 1))
        else
            log::error "Failed to remove ${group}"
        fi
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} group(s) removed"
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
  Top-level directories map to fixed targets via GNU Stow:

    home/*                       -> ~/
    config/*                     -> ~/.config/
    local/bin/*                  -> ~/.local/bin/
    local/share/completions/*    -> ~/.local/share/bash-completion/completions/

  dotfiles/
  ├── home/
  │   ├── .bashrc
  │   └── .bash_aliases
  ├── config/
  │   ├── alacritty/
  │   │   └── alacritty.toml
  │   └── starship.toml
  ├── local/
  │   ├── bin/
  │   │   └── backup.sh
  │   └── share/
  │       └── completions/
  │           └── backup
  └── ...

  Results in:
    ~/.bashrc           -> ~/.dotfiles/home/.bashrc
    ~/.config/alacritty -> ~/.dotfiles/config/alacritty

  Standalone usage (works on any system with stow):

    stow -d ~/.dotfiles -t ~        home
    stow -d ~/.dotfiles -t ~/.config config
    stow -d ~/.dotfiles/local -t ~/.local/bin bin
    stow -d ~/.dotfiles/local/share \
         -t ~/.local/share/bash-completion/completions completions

  Remove with -D flag:

    stow -d ~/.dotfiles -t ~ -D home
HELP
    printf "%b" "${COLOR_RESET}"

    ui::return_or_exit
}
