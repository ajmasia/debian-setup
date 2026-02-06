# APT sources configuration task

[[ -n "${_MOD_APT_LOADED:-}" ]] && return 0
_MOD_APT_LOADED=1

_APT_LABEL="Configure APT sources"
_APT_DESC="Manage Debian package sources: format, components,
backports, source packages (deb-src), and testing repository."

_APT_KEYRING="/usr/share/keyrings/debian-archive-keyring.gpg"

_apt::is_modernized() {
    [[ -f /etc/apt/sources.list.d/debian.sources ]]
}

_apt::has_component() {
    if _apt::is_modernized; then
        grep -rq "$1" /etc/apt/sources.list.d/debian*.sources
    else
        grep -q "$1" /etc/apt/sources.list
    fi
}

_apt::has_nonfree() {
    if _apt::is_modernized; then
        grep -rq "non-free-firmware" /etc/apt/sources.list.d/debian*.sources
    else
        grep -q "non-free-firmware" /etc/apt/sources.list
    fi
}

_apt::has_backports() {
    if _apt::is_modernized; then
        grep -rq "backports" /etc/apt/sources.list.d/debian*.sources
    else
        grep -q "backports" /etc/apt/sources.list
    fi
}

_apt::has_deb_src() {
    if _apt::is_modernized; then
        grep -rq "deb-src" /etc/apt/sources.list.d/debian*.sources
    else
        grep -q "^deb-src " /etc/apt/sources.list
    fi
}

_apt::has_testing() {
    if _apt::is_modernized; then
        grep -q "^Suites:.*testing" /etc/apt/sources.list.d/debian.sources
    else
        grep -q "^deb .* testing " /etc/apt/sources.list
    fi
}

apt::check() {
    _apt::is_modernized \
        && _apt::has_component "main" \
        && _apt::has_component "contrib" \
        && ! _apt::has_testing
}

apt::status() {
    local issues=()
    _apt::is_modernized || issues+=("not modernized")
    _apt::has_component "main" || issues+=("missing main")
    _apt::has_component "contrib" || issues+=("missing contrib")
    _apt::has_testing && issues+=("tracking testing")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

apt::apply() {
    local codename choice
    codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"

    while true; do
        # Read current state
        local is_modern=false has_nonfree=false has_backports=false has_debsrc=false has_testing=false
        _apt::is_modernized && is_modern=true
        _apt::has_nonfree && has_nonfree=true
        _apt::has_backports && has_backports=true
        _apt::has_deb_src && has_debsrc=true
        _apt::has_testing && has_testing=true

        ui::clear_content
        log::nav "Package managers > Configure APT sources"
        log::break

        # Show current status
        log::info "Current APT configuration"

        if $is_modern; then
            log::ok "Format: DEB822"
        else
            log::warn "Format: classic (not modernized)"
        fi

        if $has_testing; then
            log::ok "Release: testing"
        else
            log::ok "Release: ${codename} (stable)"
        fi

        if $has_nonfree; then
            log::ok "Non-free software: enabled"
        else
            log::warn "Non-free software: disabled"
        fi

        # Backports only relevant on stable
        if ! $has_testing; then
            if $has_backports; then
                log::ok "Backports: enabled"
            else
                log::warn "Backports: disabled"
            fi
        fi

        if $has_debsrc; then
            log::ok "Source packages (deb-src): enabled"
        else
            log::warn "Source packages (deb-src): disabled"
        fi

        log::break
        printf "%b  After changes: sudo apt update && sudo apt full-upgrade%b\n" "${COLOR_OVERLAY1}" "${COLOR_RESET}"
        log::break

        # Build options based on current state
        local options=()

        if ! $is_modern; then
            options+=("Modernize to DEB822")
        fi

        if $has_nonfree; then
            options+=("Disable non-free software")
        else
            options+=("Enable non-free software")
        fi

        # Backports only on stable; testing toggle always available
        if $has_testing; then
            options+=("Disable testing (switch back to ${codename} stable)")
        else
            if $has_backports; then
                options+=("Disable backports")
            else
                options+=("Enable backports")
            fi
            options+=("Enable testing repository")
        fi

        if $has_debsrc; then
            options+=("Disable deb-src")
        else
            options+=("Enable deb-src")
        fi

        options+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select a change to apply:" \
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
            "Modernize to DEB822")
                log::break
                log::info "Modernizing sources to DEB822 format"
                ui::flush_input
                sudo apt modernize-sources </dev/tty
                log::ok "Sources modernized to DEB822"
                is_modern=true
                # Rewrite to consolidate and add Signed-By
                _apt::_write_deb822 "$codename" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Enable non-free software")
                has_nonfree=true
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Disable non-free software")
                has_nonfree=false
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Enable backports")
                has_backports=true
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Disable backports")
                has_backports=false
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Enable deb-src")
                has_debsrc=true
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Disable deb-src")
                has_debsrc=false
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Enable testing repository")
                has_testing=true
                has_backports=false
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
            "Disable testing (switch back to ${codename} stable)")
                has_testing=false
                has_backports=true
                _apt::_apply_changes "$codename" "$is_modern" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
                ;;
        esac
    done
}

_apt::_apply_changes() {
    local codename="$1" is_modern="$2" has_nonfree="$3" has_backports="$4" has_debsrc="$5" has_testing="$6"

    log::break
    if [[ "$is_modern" == "true" ]]; then
        _apt::_write_deb822 "$codename" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
    else
        _apt::_write_classic "$codename" "$has_nonfree" "$has_backports" "$has_debsrc" "$has_testing"
    fi
    log::ok "APT sources configured"
}

_apt::_components() {
    local has_nonfree="$1"
    local components="main contrib"
    if [[ "$has_nonfree" == "true" ]]; then
        components="$components non-free non-free-firmware"
    fi
    printf '%s' "$components"
}

_apt::_write_deb822() {
    local codename="$1" has_nonfree="$2" has_backports="$3" has_debsrc="$4" has_testing="$5"

    local types="deb"
    [[ "$has_debsrc" == "true" ]] && types="deb deb-src"

    local components
    components="$(_apt::_components "$has_nonfree")"

    local content
    if [[ "$has_testing" == "true" ]]; then
        content="Types: ${types}
URIs: http://deb.debian.org/debian
Suites: testing
Components: ${components}
Signed-By: ${_APT_KEYRING}

Types: ${types}
URIs: http://deb.debian.org/debian-security
Suites: testing-security
Components: ${components}
Signed-By: ${_APT_KEYRING}"
    else
        local suites="${codename} ${codename}-updates"
        [[ "$has_backports" == "true" ]] && suites="$suites ${codename}-backports"

        content="Types: ${types}
URIs: http://deb.debian.org/debian
Suites: ${suites}
Components: ${components}
Signed-By: ${_APT_KEYRING}

Types: ${types}
URIs: http://deb.debian.org/debian-security
Suites: ${codename}-security
Components: ${components}
Signed-By: ${_APT_KEYRING}"
    fi

    log::info "Writing DEB822 sources"
    ui::flush_input
    printf '%s\n' "$content" | sudo tee /etc/apt/sources.list.d/debian.sources > /dev/null

    # Remove separate backports file if exists (consolidated into debian.sources)
    if [[ -f /etc/apt/sources.list.d/debian-backports.sources ]]; then
        sudo rm /etc/apt/sources.list.d/debian-backports.sources
        log::ok "Removed separate backports file (consolidated)"
    fi

    log::ok "DEB822 sources updated"
}

_apt::_write_classic() {
    local codename="$1" has_nonfree="$2" has_backports="$3" has_debsrc="$4" has_testing="$5"

    local components
    components="$(_apt::_components "$has_nonfree")"

    local content
    if [[ "$has_testing" == "true" ]]; then
        content="deb http://deb.debian.org/debian testing ${components}"
        [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian testing ${components}"

        content="${content}

deb http://deb.debian.org/debian-security testing-security ${components}"
        [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian-security testing-security ${components}"
    else
        content="deb http://deb.debian.org/debian ${codename} ${components}"
        [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian ${codename} ${components}"

        content="${content}

deb http://deb.debian.org/debian-security ${codename}-security ${components}"
        [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian-security ${codename}-security ${components}"

        content="${content}

deb http://deb.debian.org/debian ${codename}-updates ${components}"
        [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian ${codename}-updates ${components}"

        if [[ "$has_backports" == "true" ]]; then
            content="${content}

deb http://deb.debian.org/debian ${codename}-backports ${components}"
            [[ "$has_debsrc" == "true" ]] && content="${content}
deb-src http://deb.debian.org/debian ${codename}-backports ${components}"
        fi
    fi

    log::info "Writing classic sources"
    ui::flush_input
    printf '%s\n' "$content" | sudo tee /etc/apt/sources.list > /dev/null
    log::ok "Classic sources updated"
}
