# Dotfiles management task (custom symlinks)

[[ -n "${_MOD_DOTFILES_LOADED:-}" ]] && return 0
_MOD_DOTFILES_LOADED=1

_DOTFILES_LABEL="Configure Dotfiles"
_DOTFILES_DESC="Clone and apply dotfiles via symlinks."

_DOTFILES_DIR="$HOME/.dotfiles"
_DOTFILES_CONF_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/debian-setup"
_DOTFILES_CONF="${_DOTFILES_CONF_DIR}/dotfiles.conf"

# Mapping: repo_dir -> target_dir
_DOTFILES_MAP=(
    "home:${HOME}"
    "config:${HOME}/.config"
    "local/bin:${HOME}/.local/bin"
    "local/share/completions:${HOME}/.local/share/bash-completion/completions"
)

# ── Helpers ─────────────────────────────────────────────

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
    local mapping src_prefix target_prefix
    for mapping in "${_DOTFILES_MAP[@]}"; do
        src_prefix="${mapping%%:*}"
        target_prefix="${mapping#*:}"
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

_dotfiles::link() {
    local item="$1"
    local target
    target="$(_dotfiles::resolve_target "$item")" || return 1
    local source="${_DOTFILES_DIR}/${item}"

    # Conflict handling
    if [[ -L "$target" ]]; then
        local link_dest
        link_dest="$(readlink -f "$target")"
        local source_real
        source_real="$(readlink -f "$source")"
        if [[ "$link_dest" == "$source_real" ]]; then
            log::ok "${item} already applied"
            return 0
        fi
        log::warn "${item}: target is symlink to another location, skipped"
        return 1
    fi

    if [[ -e "$target" ]]; then
        log::warn "${item}: conflict (regular file/dir exists at target), skipped"
        return 1
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    log::ok "${item} applied"
}

_dotfiles::unlink() {
    local item="$1"
    local target
    target="$(_dotfiles::resolve_target "$item")" || return 1

    if [[ -L "$target" ]]; then
        rm "$target"
        log::ok "${item} removed"
    else
        log::warn "${item}: not a symlink, skipped"
        return 1
    fi
}

# ── Public API ──────────────────────────────────────────

dotfiles::check() {
    _dotfiles::repo_cloned
}

dotfiles::status() {
    if ! _dotfiles::repo_cloned; then
        printf '%s' "repo not cloned"
    fi
}

# ── Wizard ──────────────────────────────────────────────

dotfiles::apply() {
    local choice

    while true; do
        local repo_ok=false
        _dotfiles::repo_cloned && repo_ok=true

        ui::clear_content
        log::nav "Shell > Dotfiles"
        log::break

        log::info "Dotfiles (symlinks)"

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

        if ! $repo_ok; then
            options+=("Clone dotfiles repo")
        fi

        if $repo_ok; then
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
        local src_dir="${_DOTFILES_DIR}/${src_prefix}"
        [[ -d "$src_dir" ]] || continue

        local has_entries=false
        local entry
        for entry in "$src_dir"/* "$src_dir"/.*; do
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            [[ "$name" == "." || "$name" == ".." ]] && continue
            has_entries=true
            break
        done
        $has_entries || continue

        printf "\n%b── %s ──%b\n" "${COLOR_OVERLAY1}" "$src_prefix" "${COLOR_RESET}"

        for entry in "$src_dir"/* "$src_dir"/.*; do
            [[ -e "$entry" ]] || continue
            local name
            name="$(basename "$entry")"
            [[ "$name" == "." || "$name" == ".." ]] && continue
            local item="${src_prefix}/${name}"
            if _dotfiles::is_linked "$item"; then
                log::ok "  ${name} (applied)"
            else
                log::warn "  ${name} (not applied)"
            fi
        done
    done

    log::break
    ui::return_or_exit
}

# ── Apply all ───────────────────────────────────────────

_dotfiles::apply_all() {
    local item count=0

    while IFS= read -r item; do
        if ! _dotfiles::is_linked "$item"; then
            _dotfiles::link "$item" && count=$((count + 1))
        fi
    done < <(_dotfiles::list_items)

    log::break
    if [[ $count -gt 0 ]]; then
        log::ok "${count} item(s) applied"
    else
        log::ok "All items already applied"
    fi
}

# ── Select apply ────────────────────────────────────────

_dotfiles::select_apply() {
    local item
    local pending=()

    while IFS= read -r item; do
        if ! _dotfiles::is_linked "$item"; then
            pending+=("$item")
        fi
    done < <(_dotfiles::list_items)

    if [[ ${#pending[@]} -eq 0 ]]; then
        log::ok "All items already applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select items to apply:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${pending[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local name count=0
    while IFS= read -r name; do
        _dotfiles::link "$name" && count=$((count + 1))
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} item(s) applied"
    fi
}

# ── Select remove ───────────────────────────────────────

_dotfiles::select_remove() {
    local item
    local applied=()

    while IFS= read -r item; do
        if _dotfiles::is_linked "$item"; then
            applied+=("$item")
        fi
    done < <(_dotfiles::list_items)

    if [[ ${#applied[@]} -eq 0 ]]; then
        log::ok "No items applied"
        return
    fi

    local selected
    selected="$(gum::choose --no-limit \
        --header "Select items to remove:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "${applied[@]}")"

    if [[ -z "$selected" ]]; then
        return
    fi

    local name count=0
    while IFS= read -r name; do
        _dotfiles::unlink "$name" && count=$((count + 1))
    done <<< "$selected"

    if [[ $count -gt 0 ]]; then
        log::break
        log::ok "${count} item(s) removed"
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
    log::info "Dotfiles repo structure (symlinks)"
    log::break

    printf "%b" "${COLOR_OVERLAY1}"
    cat <<'HELP'
  Top-level directories map to fixed targets:

    home/*                       -> ~/
    config/*                     -> ~/.config/
    local/bin/*                  -> ~/.local/bin/
    local/share/completions/*    -> ~/.local/share/bash-completion/completions/

  Each entry gets its own symlink (files as file symlinks,
  directories as directory symlinks).

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
    ~/.bash_aliases     -> ~/.dotfiles/home/.bash_aliases
    ~/.config/alacritty -> ~/.dotfiles/config/alacritty
    ~/.config/starship.toml -> ~/.dotfiles/config/starship.toml
    ~/.local/bin/backup.sh -> ~/.dotfiles/local/bin/backup.sh

  No extra dependencies required (no GNU Stow needed).

  Conflicts: if a regular file/dir already exists at the target,
  the item is skipped with a warning. Remove or move the file
  first, then retry.
HELP
    printf "%b" "${COLOR_RESET}"

    ui::return_or_exit
}
