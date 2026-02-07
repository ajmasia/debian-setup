# APT package list utilities

[[ -n "${_LIB_APT_LOADED:-}" ]] && return 0
_LIB_APT_LOADED=1

apt::read_list() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log::error "Package list not found: ${file}"
        return 1
    fi
    grep -v '^\s*#' "$file" | grep -v '^\s*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

apt::is_installed() {
    local pkg="$1"
    dpkg -l "$pkg" 2>/dev/null | grep -q '^ii'
}

apt::pending_from_list() {
    local file="$1"
    local pkg
    while IFS= read -r pkg; do
        apt::is_installed "$pkg" || printf '%s\n' "$pkg"
    done < <(apt::read_list "$file")
}

apt::install_list() {
    local file="$1"
    local pending
    pending="$(apt::pending_from_list "$file")"

    if [[ -z "$pending" ]]; then
        log::ok "All packages already installed"
        return 0
    fi

    local pkgs=()
    while IFS= read -r pkg; do
        pkgs+=("$pkg")
    done <<< "$pending"

    log::info "Installing ${#pkgs[@]} package(s): ${pkgs[*]}"
    log::break
    ui::flush_input
    sudo apt-get install -y "${pkgs[@]}" </dev/tty
    hash -r
    log::break
    log::ok "Packages installed"
}

apt::list_check() {
    local file="$1"
    [[ -z "$(apt::pending_from_list "$file")" ]]
}

apt::list_status() {
    local file="$1"
    local pending count
    pending="$(apt::pending_from_list "$file")"
    if [[ -n "$pending" ]]; then
        count="$(printf '%s\n' "$pending" | wc -l)"
        printf '%s packages pending' "$count"
    fi
}

# --- .deb package functions (name|url format) ---

apt::read_deb_list() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        log::error "Package list not found: ${file}"
        return 1
    fi
    grep -v '^\s*#' "$file" | grep -v '^\s*$' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
}

apt::deb_pending() {
    local file="$1"
    local line name
    while IFS= read -r line; do
        name="${line%%|*}"
        apt::is_installed "$name" || printf '%s\n' "$line"
    done < <(apt::read_deb_list "$file")
}

apt::deb_install() {
    local name="$1"
    local url="$2"
    local tmpfile
    tmpfile="$(mktemp --suffix=.deb)"

    log::info "Downloading ${name}..."
    if ! wget -qO "$tmpfile" "$url"; then
        log::error "Failed to download ${name} from ${url}"
        rm -f "$tmpfile"
        return 1
    fi

    log::info "Installing ${name}..."
    log::break
    ui::flush_input
    if sudo apt-get install -y "$tmpfile" </dev/tty; then
        rm -f "$tmpfile"
        hash -r
        log::break
        log::ok "${name} installed"
    else
        rm -f "$tmpfile"
        hash -r
        log::break
        log::error "Failed to install ${name}"
        return 1
    fi
}

apt::deb_check() {
    local file="$1"
    [[ -z "$(apt::deb_pending "$file")" ]]
}

apt::deb_status() {
    local file="$1"
    local pending count
    pending="$(apt::deb_pending "$file")"
    if [[ -n "$pending" ]]; then
        count="$(printf '%s\n' "$pending" | wc -l)"
        printf '%s packages pending' "$count"
    fi
}

apt::deb_install_all() {
    local file="$1"
    local pending
    pending="$(apt::deb_pending "$file")"

    if [[ -z "$pending" ]]; then
        log::ok "All packages already installed"
        return 0
    fi

    local line name url
    while IFS='|' read -r name url; do
        apt::deb_install "$name" "$url" || true
    done <<< "$pending"
}

apt::list_wizard() {
    local nav_label="$1"
    local info_label="$2"
    local file="$3"
    local choice pkg

    while true; do
        ui::clear_content
        log::nav "$nav_label"
        log::break

        log::info "$info_label"

        local installed_pkgs=() pending_pkgs=()
        while IFS= read -r pkg; do
            if apt::is_installed "$pkg"; then
                installed_pkgs+=("$pkg")
            else
                pending_pkgs+=("$pkg")
            fi
        done < <(apt::read_list "$file")

        if [[ ${#installed_pkgs[@]} -gt 0 ]]; then
            log::ok "${installed_pkgs[*]}"
        fi
        if [[ ${#pending_pkgs[@]} -gt 0 ]]; then
            log::warn "${pending_pkgs[*]} (not installed)"
        fi

        log::break

        local options=()

        if [[ ${#pending_pkgs[@]} -gt 0 ]]; then
            options+=("Install all pending" "Select packages to install")
        fi

        if [[ ${#installed_pkgs[@]} -gt 0 ]]; then
            options+=("Remove packages")
        fi

        options+=("Edit packages list")
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
            "Install all pending")
                log::break
                apt::install_list "$file"
                ;;
            "Select packages to install")
                log::break
                local pending_pkgs=()
                while IFS= read -r pkg; do
                    pending_pkgs+=("$pkg")
                done < <(apt::pending_from_list "$file")

                local selected
                selected="$(gum::choose --no-limit \
                    --header "Select packages to install:" \
                    --header.foreground "$HEX_LAVENDER" \
                    --cursor.foreground "$HEX_BLUE" \
                    --item.foreground "$HEX_TEXT" \
                    --selected.foreground "$HEX_GREEN" \
                    "${pending_pkgs[@]}")"

                if [[ -n "$selected" ]]; then
                    local to_install=()
                    while IFS= read -r pkg; do
                        to_install+=("$pkg")
                    done <<< "$selected"

                    log::info "Installing ${#to_install[@]} package(s): ${to_install[*]}"
                    log::break
                    ui::flush_input
                    sudo apt-get install -y "${to_install[@]}" </dev/tty
                    hash -r
                    log::break
                    log::ok "Packages installed"
                fi
                ;;
            "Remove packages")
                log::break
                local installed_pkgs=()
                while IFS= read -r pkg; do
                    apt::is_installed "$pkg" && installed_pkgs+=("$pkg")
                done < <(apt::read_list "$file")

                local selected
                selected="$(gum::choose --no-limit \
                    --header "Select packages to remove:" \
                    --header.foreground "$HEX_LAVENDER" \
                    --cursor.foreground "$HEX_BLUE" \
                    --item.foreground "$HEX_TEXT" \
                    --selected.foreground "$HEX_GREEN" \
                    "${installed_pkgs[@]}")"

                if [[ -n "$selected" ]]; then
                    local to_remove=()
                    while IFS= read -r pkg; do
                        to_remove+=("$pkg")
                    done <<< "$selected"

                    log::info "Removing ${#to_remove[@]} package(s): ${to_remove[*]}"
                    log::break
                    ui::flush_input
                    sudo apt-get remove -y "${to_remove[@]}" </dev/tty
                    hash -r
                    log::break
                    log::ok "Packages removed"
                fi
                ;;
            "Edit packages list")
                "${EDITOR:-vi}" "$file" </dev/tty
                ;;
        esac
    done
}

apt::deb_wizard() {
    local nav_label="$1"
    local info_label="$2"
    local file="$3"
    local choice line name url

    while true; do
        ui::clear_content
        log::nav "$nav_label"
        log::break

        log::info "$info_label"

        local installed_names=() pending_names_display=()
        while IFS='|' read -r name url; do
            if apt::is_installed "$name"; then
                installed_names+=("$name")
            else
                pending_names_display+=("$name")
            fi
        done < <(apt::read_deb_list "$file")

        if [[ ${#installed_names[@]} -gt 0 ]]; then
            log::ok "${installed_names[*]}"
        fi
        if [[ ${#pending_names_display[@]} -gt 0 ]]; then
            log::warn "${pending_names_display[*]} (not installed)"
        fi

        log::break

        local options=()

        if [[ ${#pending_names_display[@]} -gt 0 ]]; then
            options+=("Install all pending" "Select packages to install")
        fi

        if [[ ${#installed_names[@]} -gt 0 ]]; then
            options+=("Remove packages")
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
            "Install all pending")
                log::break
                apt::deb_install_all "$file"
                ;;
            "Select packages to install")
                log::break
                local pending_names=()
                local -A pending_urls=()
                while IFS='|' read -r name url; do
                    pending_names+=("$name")
                    pending_urls["$name"]="$url"
                done < <(apt::deb_pending "$file")

                local selected
                selected="$(gum::choose --no-limit \
                    --header "Select packages to install:" \
                    --header.foreground "$HEX_LAVENDER" \
                    --cursor.foreground "$HEX_BLUE" \
                    --item.foreground "$HEX_TEXT" \
                    --selected.foreground "$HEX_GREEN" \
                    "${pending_names[@]}")"

                if [[ -n "$selected" ]]; then
                    while IFS= read -r name; do
                        apt::deb_install "$name" "${pending_urls[$name]}" || true
                    done <<< "$selected"
                fi
                ;;
            "Remove packages")
                log::break
                local installed_pkgs=()
                while IFS='|' read -r name url; do
                    apt::is_installed "$name" && installed_pkgs+=("$name")
                done < <(apt::read_deb_list "$file")

                local selected
                selected="$(gum::choose --no-limit \
                    --header "Select packages to remove:" \
                    --header.foreground "$HEX_LAVENDER" \
                    --cursor.foreground "$HEX_BLUE" \
                    --item.foreground "$HEX_TEXT" \
                    --selected.foreground "$HEX_GREEN" \
                    "${installed_pkgs[@]}")"

                if [[ -n "$selected" ]]; then
                    local to_remove=()
                    while IFS= read -r name; do
                        to_remove+=("$name")
                    done <<< "$selected"

                    log::info "Removing ${#to_remove[@]} package(s): ${to_remove[*]}"
                    log::break
                    ui::flush_input
                    sudo apt-get remove -y "${to_remove[@]}" </dev/tty
                    hash -r
                    log::break
                    log::ok "Packages removed"
                fi
                ;;
        esac
    done
}
