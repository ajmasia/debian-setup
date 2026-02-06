# APT sources configuration task

[[ -n "${_MOD_APT_LOADED:-}" ]] && return 0
_MOD_APT_LOADED=1

_APT_LABEL="Configure APT sources"
_APT_DESC="Verifies and configures Debian package sources: components,
backports, and source packages (deb-src)."

_apt::is_modernized() {
    [[ -f /etc/apt/sources.list.d/debian.sources ]]
}

_apt::sources_file() {
    if _apt::is_modernized; then
        printf '%s' "/etc/apt/sources.list.d/debian.sources"
    else
        printf '%s' "/etc/apt/sources.list"
    fi
}

_apt::has_component() {
    local component="$1"
    grep -q "$component" "$(_apt::sources_file)"
}

_apt::has_backports() {
    grep -q "backports" "$(_apt::sources_file)"
}

_apt::has_deb_src() {
    local file
    file="$(_apt::sources_file)"
    if _apt::is_modernized; then
        grep -q "deb-src" "$file"
    else
        grep -q "^deb-src " "$file"
    fi
}

apt::check() {
    _apt::has_component "non-free-firmware" \
        && _apt::has_backports \
        && _apt::has_deb_src
}

apt::apply() {
    local codename sources_file
    codename="$(. /etc/os-release && printf '%s' "$VERSION_CODENAME")"
    sources_file="$(_apt::sources_file)"

    log::info "Reading APT sources"

    # Show current component status
    local components="main"
    for comp in contrib non-free non-free-firmware; do
        if _apt::has_component "$comp"; then
            components="${components} ${comp}"
        fi
    done
    log::ok "Components: ${components}"

    if _apt::has_backports; then
        log::ok "Backports: ${codename}-backports"
    else
        log::warn "Missing: backports"
    fi

    if _apt::has_deb_src; then
        log::ok "Source packages: deb-src"
    else
        log::warn "Missing: deb-src"
    fi

    log::break

    # Offer modernization on Debian 13+
    local modernize="no"
    if ! _apt::is_modernized && command -v apt &>/dev/null; then
        local apt_version
        apt_version="$(apt --version 2>/dev/null | head -1)"
        if [[ "$apt_version" == *"3."* ]]; then
            local choice
            choice="$(gum::choose \
                --header "Debian 13 detected. Modernize sources to DEB822 format?" \
                --header.foreground "$HEX_LAVENDER" \
                --cursor.foreground "$HEX_BLUE" \
                --item.foreground "$HEX_TEXT" \
                --selected.foreground "$HEX_GREEN" \
                "Yes" \
                "No")"

            if [[ "$choice" == "Yes" ]]; then
                modernize="yes"
                log::info "Modernizing sources to DEB822 format"
                ui::flush_input
                sudo apt modernize-sources </dev/tty
                log::ok "Sources modernized to DEB822"
                log::break
                sources_file="$(_apt::sources_file)"
            fi
        fi
    fi

    # Generate correct content based on format
    if _apt::is_modernized; then
        _apt::_write_deb822 "$codename"
    else
        _apt::_write_classic "$codename"
    fi

    log::ok "APT sources configured"
    log::break
    log::info "Run the following to update your system:"
    printf "%b  sudo apt update && sudo apt full-upgrade%b\n" "${COLOR_OVERLAY1}" "${COLOR_RESET}"
}

_apt::_write_deb822() {
    local codename="$1"

    local content
    content="$(cat <<EOF
Types: deb deb-src
URIs: http://deb.debian.org/debian
Suites: ${codename} ${codename}-updates ${codename}-backports
Components: main contrib non-free non-free-firmware

Types: deb deb-src
URIs: http://deb.debian.org/debian-security
Suites: ${codename}-security
Components: main contrib non-free non-free-firmware
EOF
)"

    local current
    current="$(cat /etc/apt/sources.list.d/debian.sources 2>/dev/null)"

    if [[ "$current" != "$content" ]]; then
        log::info "Updating DEB822 sources"
        ui::flush_input
        printf '%s\n' "$content" | sudo tee /etc/apt/sources.list.d/debian.sources > /dev/null
        log::ok "DEB822 sources updated"
    fi
}

_apt::_write_classic() {
    local codename="$1"

    local content
    content="$(cat <<EOF
deb http://deb.debian.org/debian ${codename} main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian ${codename} main contrib non-free non-free-firmware

deb http://deb.debian.org/debian-security ${codename}-security main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian-security ${codename}-security main contrib non-free non-free-firmware

deb http://deb.debian.org/debian ${codename}-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian ${codename}-updates main contrib non-free non-free-firmware

deb http://deb.debian.org/debian ${codename}-backports main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian ${codename}-backports main contrib non-free non-free-firmware
EOF
)"

    local current
    current="$(cat /etc/apt/sources.list 2>/dev/null)"

    if [[ "$current" != "$content" ]]; then
        log::info "Updating classic sources"
        ui::flush_input
        printf '%s\n' "$content" | sudo tee /etc/apt/sources.list > /dev/null
        log::ok "Classic sources updated"
    fi
}
