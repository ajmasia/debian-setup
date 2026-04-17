#!/usr/bin/env bash
set -euo pipefail

# Constants
REPO_HTTPS="https://github.com/ajmasia/debian-setup.git"
REPO_SSH="git@github.com:ajmasia/debian-setup.git"
APP_NAME="debian-setup"
INSTALL_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/${APP_NAME}"
BIN_DIR="$HOME/.local/bin"
BIN_PATH="${BIN_DIR}/${APP_NAME}"
BIN_PATH_SHORT="${BIN_DIR}/ds"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/${APP_NAME}"
BASHRC="$HOME/.bashrc"
PATH_MARKER="# debian-setup"
BASH_COMP_DIR="$HOME/.local/share/bash-completion/completions"
ZSH_COMP_DIR="$HOME/.local/share/zsh/site-functions"
BASH_COMP_LINK="${BASH_COMP_DIR}/debian-setup"
BASH_COMP_LINK_DS="${BASH_COMP_DIR}/ds"
ZSH_COMP_LINK="${ZSH_COMP_DIR}/_debian-setup"
ZSH_COMP_LINK_DS="${ZSH_COMP_DIR}/_ds"

# Colors (self-contained, no deps)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Helpers ----------------------------------------------------------------

info()  { printf "${BLUE}${BOLD}::${RESET} %s\n" "$1"; }
ok()    { printf "${GREEN}${BOLD} ✓${RESET} %s\n" "$1"; }
warn()  { printf "${YELLOW}${BOLD} !${RESET} %s\n" "$1"; }
error() { printf "${RED}${BOLD} ✗${RESET} %s\n" "$1" >&2; }

get_version() {
    if [[ -f "${INSTALL_DIR}/VERSION" ]]; then
        cat "${INSTALL_DIR}/VERSION"
    else
        echo "unknown"
    fi
}

check_prereqs() {
    local missing=()

    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        missing+=("bash >= 4 (found ${BASH_VERSION})")
    fi
    command -v git &>/dev/null || missing+=("git")
    command -v curl &>/dev/null || missing+=("curl")

    if [[ ${#missing[@]} -gt 0 ]]; then
        error "Missing prerequisites:"
        for dep in "${missing[@]}"; do
            printf "  - %s\n" "$dep" >&2
        done
        printf "\nInstall them as root with: su -c 'apt-get install -y git curl'\n" >&2
        exit 1
    fi
}

ensure_path() {
    case ":${PATH}:" in
        *":${BIN_DIR}:"*) return 0 ;;
    esac

    if [[ -f "$BASHRC" ]] && grep -Fq "$PATH_MARKER" "$BASHRC"; then
        return 0
    fi

    info "Adding ${BIN_DIR} to PATH in ${BASHRC}"
    printf '\nexport PATH="%s:$PATH" %s\n' "$BIN_DIR" "$PATH_MARKER" >> "$BASHRC"
    ok "PATH updated (restart your shell or run: source ~/.bashrc)"
}

refresh_completions() {
    local refreshed=false
    if [[ -L "$BASH_COMP_LINK" ]]; then
        ln -sf "${INSTALL_DIR}/completions/debian-setup.bash" "$BASH_COMP_LINK"
        ln -sf "${INSTALL_DIR}/completions/debian-setup.bash" "$BASH_COMP_LINK_DS"
        refreshed=true
    fi
    if [[ -L "$ZSH_COMP_LINK" ]]; then
        ln -sf "${INSTALL_DIR}/completions/debian-setup.zsh" "$ZSH_COMP_LINK"
        ln -sf "${INSTALL_DIR}/completions/debian-setup.zsh" "$ZSH_COMP_LINK_DS"
        refreshed=true
    fi
    $refreshed && ok "Shell completions refreshed"
}

remove_completions() {
    [[ -L "$BASH_COMP_LINK" ]] && rm "$BASH_COMP_LINK"
    [[ -L "$BASH_COMP_LINK_DS" ]] && rm "$BASH_COMP_LINK_DS"
    [[ -L "$ZSH_COMP_LINK" ]] && rm "$ZSH_COMP_LINK"
    [[ -L "$ZSH_COMP_LINK_DS" ]] && rm "$ZSH_COMP_LINK_DS"
    ok "Shell completions removed"
}

clean_path() {
    if [[ -f "$BASHRC" ]] && grep -Fq "$PATH_MARKER" "$BASHRC"; then
        local tmp
        tmp=$(mktemp)
        grep -Fv "$PATH_MARKER" "$BASHRC" > "$tmp"
        mv "$tmp" "$BASHRC"
        ok "Cleaned PATH entry from ${BASHRC}"
    fi
}

# --- Actions ----------------------------------------------------------------

install_gum() {
    if command -v gum &>/dev/null; then
        ok "gum already installed"
        return 0
    fi

    info "Installing gum (required dependency)..."

    if ! command -v gpg &>/dev/null; then
        info "Installing gpg..."
        if sudo -n true 2>/dev/null || groups | grep -qw sudo; then
            sudo apt-get update -qq && sudo apt-get install -y gpg
        else
            su -c "apt-get update -qq && apt-get install -y gpg" </dev/tty
        fi
    fi

    local tmpkey
    tmpkey="$(mktemp)"
    if ! curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o "$tmpkey"; then
        rm -f "$tmpkey"
        error "Failed to download gum GPG key"
        exit 1
    fi

    if sudo -n true 2>/dev/null || groups | grep -qw sudo; then
        sudo mkdir -p /etc/apt/keyrings
        sudo mv "$tmpkey" /etc/apt/keyrings/charm.gpg
        sudo chmod 644 /etc/apt/keyrings/charm.gpg
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" \
            | sudo tee /etc/apt/sources.list.d/charm.list > /dev/null
        sudo apt-get update -qq
        sudo apt-get install -y gum
    else
        su -c "
            mkdir -p /etc/apt/keyrings
            mv '$tmpkey' /etc/apt/keyrings/charm.gpg
            chmod 644 /etc/apt/keyrings/charm.gpg
            echo 'deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *' \
                > /etc/apt/sources.list.d/charm.list
            apt-get update -qq
            apt-get install -y gum
        " </dev/tty
    fi

    if ! command -v gum &>/dev/null; then
        error "gum installation failed"
        exit 1
    fi

    ok "gum installed"
}

do_install() {
    info "Installing ${APP_NAME}..."
    printf "\n"

    check_prereqs

    if [[ -d "${INSTALL_DIR}/.git" ]]; then
        warn "Already installed at ${INSTALL_DIR}"
        printf "  Run ${BOLD}%s --update${RESET} to update\n" "$APP_NAME"
        printf "  Run ${BOLD}%s --uninstall${RESET} to remove\n" "$APP_NAME"
        exit 0
    fi

    # Clone — try HTTPS first, fallback to SSH
    info "Cloning repository..."
    if git clone --branch main "$REPO_HTTPS" "$INSTALL_DIR" 2>/dev/null; then
        ok "Cloned via HTTPS"
    elif git clone --branch main "$REPO_SSH" "$INSTALL_DIR"; then
        ok "Cloned via SSH"
    else
        error "Failed to clone repository"
        exit 1
    fi

    # gum (hard dependency)
    printf "\n"
    install_gum

    # Symlinks
    mkdir -p "$BIN_DIR"
    ln -sf "${INSTALL_DIR}/${APP_NAME}" "$BIN_PATH"
    ln -sf "${INSTALL_DIR}/${APP_NAME}" "$BIN_PATH_SHORT"
    ok "Symlinks created: ${BIN_PATH}, ${BIN_PATH_SHORT}"

    # PATH
    ensure_path

    printf "\n"
    ok "${APP_NAME} $(get_version) installed successfully"
    printf "\n"
    printf "  Run ${BOLD}ds${RESET} or ${BOLD}%s${RESET} to start\n" "$APP_NAME"
    printf "  Run ${BOLD}ds --completions${RESET} to enable tab completions\n"
    printf "  Run ${BOLD}ds --update${RESET} to update later\n"
    printf "  Run ${BOLD}ds --uninstall${RESET} to remove\n"
    printf "\n"

    if ! echo "$PATH" | grep -Fq "$BIN_DIR"; then
        warn "Restart your shell or run: source ~/.bashrc"
    fi
}

do_update() {
    info "Updating ${APP_NAME}..."
    printf "\n"

    if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
        error "Not installed. Run the installer first."
        exit 1
    fi

    local old_version
    old_version=$(get_version)

    if ! git -C "$INSTALL_DIR" pull --ff-only; then
        error "Update failed. You may have local changes in ${INSTALL_DIR}"
        printf "  Try: cd %s && git status\n" "$INSTALL_DIR" >&2
        exit 1
    fi

    # Ensure symlinks are correct (in case install dir changed)
    mkdir -p "$BIN_DIR"
    ln -sf "${INSTALL_DIR}/${APP_NAME}" "$BIN_PATH"
    ln -sf "${INSTALL_DIR}/${APP_NAME}" "$BIN_PATH_SHORT"

    # Refresh completions if installed
    refresh_completions

    local new_version
    new_version=$(get_version)

    printf "\n"
    if [[ "$old_version" == "$new_version" ]]; then
        ok "Already up to date (${new_version})"
    else
        ok "Updated: ${old_version} → ${new_version}"
    fi
}

do_uninstall() {
    info "Uninstalling ${APP_NAME}..."
    printf "\n"

    if [[ ! -d "${INSTALL_DIR}" ]] && [[ ! -L "$BIN_PATH" ]]; then
        warn "Not installed, nothing to do"
        exit 0
    fi

    # Remove symlinks
    if [[ -L "$BIN_PATH" ]]; then
        rm "$BIN_PATH"
        ok "Removed symlink: ${BIN_PATH}"
    fi
    if [[ -L "$BIN_PATH_SHORT" ]]; then
        rm "$BIN_PATH_SHORT"
        ok "Removed symlink: ${BIN_PATH_SHORT}"
    fi

    # Remove repo
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        ok "Removed: ${INSTALL_DIR}"
    fi

    # Offer to remove logs
    if [[ -d "$STATE_DIR" ]]; then
        printf "\n"
        printf "  Log directory found: ${STATE_DIR}\n"
        printf "  Remove logs? [y/N] "

        local answer=""
        if [[ -t 0 ]]; then
            read -r answer </dev/tty || true
        else
            answer="n"
        fi

        if [[ "$answer" =~ ^[Yy]$ ]]; then
            rm -rf "$STATE_DIR"
            ok "Removed: ${STATE_DIR}"
        else
            info "Logs kept at: ${STATE_DIR}"
        fi
    fi

    # Remove completions
    remove_completions

    # Clean PATH from .bashrc
    clean_path

    printf "\n"
    ok "${APP_NAME} uninstalled"
}

# --- Main -------------------------------------------------------------------

case "${1:-}" in
    --update)    do_update ;;
    --uninstall) do_uninstall ;;
    -h|--help)
        printf "Usage: install.sh [--update | --uninstall]\n\n"
        printf "  (no flags)     Install %s\n" "$APP_NAME"
        printf "  --update       Update to latest version\n"
        printf "  --uninstall    Remove %s and clean up\n" "$APP_NAME"
        ;;
    "")          do_install ;;
    *)
        error "Unknown option: $1"
        printf "Usage: install.sh [--update | --uninstall]\n" >&2
        exit 1
        ;;
esac
