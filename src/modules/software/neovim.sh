# Neovim + LazyVim software task

[[ -n "${_MOD_NEOVIM_LOADED:-}" ]] && return 0
_MOD_NEOVIM_LOADED=1

_NEOVIM_LABEL="Configure Neovim"
_NEOVIM_DESC="Install Neovim and configure LazyVim."

_NEOVIM_INSTALL_DIR="$HOME/.local"
_NEOVIM_TARBALL_URL="https://github.com/neovim/neovim/releases/download/stable/nvim-linux-x86_64.tar.gz"
_NEOVIM_CONFIG_DIR="$HOME/.config/nvim"
_NEOVIM_LAZYGIT_API="https://api.github.com/repos/jesseduffield/lazygit/releases/latest"

# --- Private detection functions ---

_neovim::is_installed() {
    [[ -x "$_NEOVIM_INSTALL_DIR/bin/nvim" ]]
}

_neovim::session_ready() {
    command -v nvim &>/dev/null
}

_neovim::lazyvim_configured() {
    local config_dir="${1:-$_NEOVIM_CONFIG_DIR}"
    [[ -f "$config_dir/lua/config/lazy.lua" ]]
}

_neovim::find_lazyvim_dir() {
    local dir
    for dir in "$HOME"/.config/nvim "$HOME"/.config/lazyvim; do
        if _neovim::lazyvim_configured "$dir"; then
            printf '%s' "$dir"
            return 0
        fi
    done
    # Check custom dirs that have lazy.lua
    for dir in "$HOME"/.config/*/; do
        [[ -d "$dir" ]] || continue
        if _neovim::lazyvim_configured "$dir"; then
            printf '%s' "$dir"
            return 0
        fi
    done
    return 1
}

# --- Public API ---

neovim::check() {
    _neovim::is_installed && _neovim::session_ready
}

neovim::status() {
    local issues=()
    _neovim::is_installed || issues+=("not installed")
    _neovim::is_installed && ! _neovim::session_ready && issues+=("restart needed")
    if [[ ${#issues[@]} -gt 0 ]]; then
        local IFS=", "
        printf '%s' "${issues[*]}"
    fi
}

neovim::apply() {
    local choice

    while true; do
        local installed=false session_ready=false lazyvim_dir=""
        _neovim::is_installed && installed=true
        _neovim::session_ready && session_ready=true
        lazyvim_dir="$(_neovim::find_lazyvim_dir 2>/dev/null || true)"

        ui::clear_content
        log::nav "Software > Neovim"
        log::break

        log::info "Neovim"

        if $installed; then
            if $session_ready; then
                local version
                version="$(nvim --version 2>/dev/null | head -1 || true)"
                log::ok "Neovim ${version}"
            else
                log::ok "Neovim installed"
                log::warn "Restart needed to activate nvim in current session"
            fi
        else
            log::warn "Neovim (not installed)"
        fi

        if [[ -n "$lazyvim_dir" ]]; then
            local config_name
            config_name="$(basename "$lazyvim_dir")"
            log::ok "LazyVim (${config_name})"
        else
            log::warn "LazyVim (not configured)"
        fi

        log::break

        # Build options based on current state
        local options=()

        if $installed; then
            options+=("Update Neovim")
        else
            options+=("Install Neovim")
        fi

        if $installed && [[ -z "$lazyvim_dir" ]]; then
            options+=("Configure LazyVim")
        fi

        if $installed; then
            options+=("Remove Neovim")
        fi

        if [[ -n "$lazyvim_dir" ]]; then
            options+=("Remove LazyVim")
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
            "Install Neovim"|"Update Neovim")
                log::break
                _neovim::install
                ;;
            "Configure LazyVim")
                _neovim::configure_lazyvim
                ;;
            "Remove Neovim")
                log::break
                _neovim::remove
                ;;
            "Remove LazyVim")
                log::break
                _neovim::remove_lazyvim "$lazyvim_dir"
                ;;
        esac
    done
}

# --- Install/Update Neovim ---

_neovim::install() {
    log::info "Downloading Neovim stable"

    local tmpfile
    tmpfile="$(mktemp)"

    if ! wget -qO "$tmpfile" "$_NEOVIM_TARBALL_URL"; then
        log::error "Failed to download Neovim"
        rm -f "$tmpfile"
        return
    fi

    log::ok "Download complete"

    mkdir -p "$_NEOVIM_INSTALL_DIR"
    tar -xzf "$tmpfile" -C "$_NEOVIM_INSTALL_DIR" --strip-components=1
    rm -f "$tmpfile"
    hash -r

    local version
    version="$("$_NEOVIM_INSTALL_DIR/bin/nvim" --version 2>/dev/null | head -1 || true)"
    log::ok "Neovim installed (${version})"

    # Check if ~/.local/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        log::break
        log::warn "~/.local/bin is not in your PATH"
        log::warn "Add to .bashrc: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# --- Remove Neovim ---

_neovim::remove() {
    log::info "Removing Neovim"

    rm -f "$_NEOVIM_INSTALL_DIR/bin/nvim"
    rm -rf "$_NEOVIM_INSTALL_DIR/lib/nvim"
    rm -rf "$_NEOVIM_INSTALL_DIR/share/nvim"
    hash -r

    log::ok "Neovim removed"
}

# --- Configure LazyVim ---

_neovim::configure_lazyvim() {
    # Step 1: Choose config directory name
    local config_name choice

    ui::clear_content
    log::nav "Software > Neovim > Configure LazyVim"
    log::break

    log::info "Choose Neovim config directory name"
    log::break

    choice="$(gum::choose \
        --header "Config directory (~/.config/<name>):" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "nvim (default)" "lazyvim" "Custom name" "Back")"

    case "$choice" in
        ""|"Back") return ;;
        "nvim (default)") config_name="nvim" ;;
        "lazyvim") config_name="lazyvim" ;;
        "Custom name")
            config_name="$(gum::input \
                --header "Enter config directory name:" \
                --header.foreground "$HEX_LAVENDER" \
                --placeholder "e.g. nvim-lazy")"
            if [[ -z "$config_name" ]]; then
                return
            fi
            ;;
    esac

    local config_dir="$HOME/.config/$config_name"

    # Step 2: Handle existing config
    if [[ -d "$config_dir" ]]; then
        log::break
        log::warn "Directory ${config_dir} already exists"

        local action
        action="$(gum::choose \
            --header "How to handle existing config?" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Backup and replace" "Delete and replace" "Cancel")"

        case "$action" in
            ""|"Cancel") return ;;
            "Backup and replace")
                local backup="${config_dir}.bak.$(date +%Y%m%d%H%M%S)"
                mv "$config_dir" "$backup"
                log::ok "Backed up to ${backup}"
                ;;
            "Delete and replace")
                rm -rf "$config_dir"
                log::ok "Deleted ${config_dir}"
                ;;
        esac
    fi

    # Step 3: Install missing APT dependencies
    _neovim::install_deps

    # Step 4: Install lazygit
    _neovim::install_lazygit

    # Step 5: Install tree-sitter-cli
    _neovim::install_treesitter

    # Step 6: Clone LazyVim starter
    log::break
    log::info "Cloning LazyVim starter"

    if git clone https://github.com/LazyVim/starter "$config_dir" 2>/dev/null; then
        rm -rf "$config_dir/.git"
        log::ok "LazyVim starter cloned to ${config_dir}"
    else
        log::error "Failed to clone LazyVim starter"
        return
    fi

    # Step 7: Catppuccin colorscheme
    _neovim::setup_colorscheme "$config_dir"

    # Step 8: NVIM_APPNAME instructions
    if [[ "$config_name" != "nvim" ]]; then
        log::break
        log::info "Custom config directory: ${config_name}"
        log::warn "Run with: NVIM_APPNAME=${config_name} nvim"

        local add_alias
        add_alias="$(gum::choose \
            --header "Add alias to .bash_aliases?" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Yes" "No")"

        if [[ "$add_alias" == "Yes" ]]; then
            local alias_line="alias ${config_name}='NVIM_APPNAME=${config_name} nvim'"
            local aliases_file="$HOME/.bash_aliases"

            if [[ -f "$aliases_file" ]] && grep -Fq "$alias_line" "$aliases_file"; then
                log::ok "Alias already exists"
            else
                printf '\n# LazyVim (%s)\n%s\n' "$config_name" "$alias_line" >> "$aliases_file"
                log::ok "Added alias: ${config_name}"
                log::warn "Restart your shell or run: source ~/.bash_aliases"
            fi
        fi
    fi

    log::break
    log::ok "LazyVim configuration complete"
}

# --- Install APT dependencies for LazyVim ---

_neovim::install_deps() {
    log::break
    log::info "Checking LazyVim dependencies"

    local deps=("python3-venv" "python3-pip" "luarocks")

    # Auto-detect clipboard tool
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        if ! apt::is_installed "wl-clipboard"; then
            deps+=("wl-clipboard")
        fi
    fi

    local missing=()
    local dep
    for dep in "${deps[@]}"; do
        if apt::is_installed "$dep"; then
            log::ok "$dep"
        else
            log::warn "${dep} (not installed)"
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        log::ok "All dependencies installed"
        return
    fi

    log::break
    local install
    install="$(gum::choose \
        --header "Install ${#missing[@]} missing dependencies?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$install" == "Yes" ]]; then
        log::info "Installing ${missing[*]}"
        log::break
        ui::flush_input
        if sudo apt-get install -y "${missing[@]}" </dev/tty; then
            hash -r
            log::break
            log::ok "Dependencies installed"
        else
            hash -r
            log::break
            log::error "Failed to install dependencies"
        fi
    fi
}

# --- Install lazygit ---

_neovim::install_lazygit() {
    if command -v lazygit &>/dev/null; then
        return
    fi

    log::break
    local install
    install="$(gum::choose \
        --header "Install lazygit (recommended for LazyVim)?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$install" != "Yes" ]]; then
        return
    fi

    log::info "Fetching latest lazygit version"

    local json version
    json="$(curl -fsSL "$_NEOVIM_LAZYGIT_API" 2>/dev/null || true)"

    if [[ -z "$json" ]]; then
        log::error "Failed to fetch lazygit release info"
        return
    fi

    version="$(printf '%s' "$json" | grep -oP '"tag_name":\s*"v?\K[^"]+' | head -1)"

    if [[ -z "$version" ]]; then
        log::error "Failed to parse lazygit version"
        return
    fi

    log::ok "Latest version: ${version}"

    local arch
    arch="$(uname -m)"
    case "$arch" in
        x86_64) arch="x86_64" ;;
        aarch64) arch="arm64" ;;
        *)
            log::error "Unsupported architecture: ${arch}"
            return
            ;;
    esac

    local url="https://github.com/jesseduffield/lazygit/releases/download/v${version}/lazygit_${version}_Linux_${arch}.tar.gz"
    local tmpdir
    tmpdir="$(mktemp -d)"

    log::info "Downloading lazygit ${version}"
    if ! wget -qO "$tmpdir/lazygit.tar.gz" "$url"; then
        log::error "Failed to download lazygit"
        rm -rf "$tmpdir"
        return
    fi

    tar -xzf "$tmpdir/lazygit.tar.gz" -C "$tmpdir"

    ui::flush_input
    sudo mv "$tmpdir/lazygit" /usr/local/bin/lazygit </dev/tty
    sudo chmod 755 /usr/local/bin/lazygit
    rm -rf "$tmpdir"
    hash -r

    log::ok "lazygit ${version} installed"
}

# --- Install tree-sitter-cli ---

_neovim::install_treesitter() {
    if command -v tree-sitter &>/dev/null; then
        return
    fi

    if ! command -v npm &>/dev/null; then
        return
    fi

    log::break
    local install
    install="$(gum::choose \
        --header "Install tree-sitter-cli via npm (recommended)?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$install" == "Yes" ]]; then
        log::info "Installing tree-sitter-cli"
        if npm install -g tree-sitter-cli 2>/dev/null; then
            hash -r
            log::ok "tree-sitter-cli installed"
        else
            log::error "Failed to install tree-sitter-cli"
        fi
    fi
}

# --- Catppuccin colorscheme ---

_neovim::setup_colorscheme() {
    local config_dir="$1"

    log::break
    local setup
    setup="$(gum::choose \
        --header "Set up Catppuccin colorscheme?" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "Yes" "No")"

    if [[ "$setup" != "Yes" ]]; then
        return
    fi

    local flavour
    flavour="$(gum::choose \
        --header "Select Catppuccin flavour:" \
        --header.foreground "$HEX_LAVENDER" \
        --cursor.foreground "$HEX_BLUE" \
        --item.foreground "$HEX_TEXT" \
        --selected.foreground "$HEX_GREEN" \
        "mocha" "macchiato" "frappe" "latte")"

    if [[ -z "$flavour" ]]; then
        return
    fi

    mkdir -p "$config_dir/lua/plugins"
    cat > "$config_dir/lua/plugins/colorscheme.lua" << EOF
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "${flavour}",
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
EOF

    log::ok "Catppuccin ${flavour} colorscheme configured"
}

# --- Remove LazyVim ---

_neovim::remove_lazyvim() {
    local config_dir="$1"
    local config_name
    config_name="$(basename "$config_dir")"

    log::info "Removing LazyVim (${config_name})"

    rm -rf "$config_dir"
    rm -rf "$HOME/.local/share/$config_name"
    rm -rf "$HOME/.local/state/$config_name"
    rm -rf "$HOME/.cache/$config_name"

    log::ok "LazyVim data removed"

    # Clean alias from .bash_aliases if present
    local aliases_file="$HOME/.bash_aliases"
    if [[ "$config_name" != "nvim" && -f "$aliases_file" ]]; then
        local alias_line="alias ${config_name}='NVIM_APPNAME=${config_name} nvim'"
        if grep -Fq "$alias_line" "$aliases_file"; then
            local tmp
            tmp="$(mktemp)"
            grep -Fv "$alias_line" "$aliases_file" | grep -v "# LazyVim (${config_name})" > "$tmp" || true
            mv "$tmp" "$aliases_file"
            log::ok "Cleaned alias from .bash_aliases"
        fi
    fi

    log::ok "LazyVim removed"
}
