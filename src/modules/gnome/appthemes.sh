# App themes task (informational)

[[ -n "${_MOD_APPTHEMES_LOADED:-}" ]] && return 0
_MOD_APPTHEMES_LOADED=1

_APPTHEMES_LABEL="App Themes"
_APPTHEMES_DESC="Catppuccin Mocha theme install guide for CLI apps."

# Always OK — informational only
appthemes::check() { return 0; }
appthemes::status() { :; }

appthemes::apply() {
    while true; do
        ui::clear_content
        log::nav "UI > App Themes"
        log::break

        log::info "Catppuccin Mocha — CLI app themes"
        log::break

        printf "%b" "${COLOR_OVERLAY1}"
        cat <<'HELP'
  btop
  ────
  1. Download Mocha theme from GitHub releases:
     https://github.com/catppuccin/btop/releases/latest
  2. Copy to ~/.config/btop/themes/
  3. In btop: Esc > Options > select Mocha

  Alacritty
  ─────────
  1. Download theme file:
     curl -LO --output-dir ~/.config/alacritty \
       https://github.com/catppuccin/alacritty/raw/main/catppuccin-mocha.toml
  2. Add to alacritty.toml:
     general.import = ["~/.config/alacritty/catppuccin-mocha.toml"]

  Atuin
  ─────
  1. Download Mocha theme (pick accent) from:
     https://github.com/catppuccin/atuin/tree/main/themes
  2. Copy to ~/.config/atuin/themes/
  3. Add to ~/.config/atuin/config.toml:
     [theme]
     name = "catppuccin-mocha-mauve"

  bat
  ───
  1. Download theme:
     mkdir -p "$(bat --config-dir)/themes"
     wget -P "$(bat --config-dir)/themes" \
       https://github.com/catppuccin/bat/raw/main/themes/Catppuccin%20Mocha.tmTheme
  2. Rebuild cache: bat cache --build
  3. Add to ~/.config/bat/config:
     --theme="Catppuccin Mocha"

  cava
  ────
  1. Download Mocha theme from:
     https://github.com/catppuccin/cava/tree/main/themes
  2. Replace gradient settings in ~/.config/cava/config
     with the content from mocha.cava (or mocha-transparent.cava)

  eza
  ───
  1. Download Mocha theme (pick accent) from:
     https://github.com/catppuccin/eza/tree/main/themes/mocha
  2. Copy YAML content to eza theme config
     (see: man eza_colors-explanation)

  lazygit
  ───────
  Add to ~/.config/lazygit/config.yml:
     gui:
       theme:
         activeBorderColor: ["#89b4fa", bold]
         inactiveBorderColor: ["#a6adc8"]
         optionsTextColor: ["#89b4fa"]
         selectedLineBgColor: ["#313244"]
         cherryPickedCommitBgColor: ["#45475a"]
         cherryPickedCommitFgColor: ["#89b4fa"]
         unstagedChangesColor: ["#f38ba8"]
         defaultFgColor: ["#cdd6f4"]
         searchingActiveBorderColor: ["#f9e2af"]

  Starship
  ────────
  1. Add to starship.toml:
     palette = "catppuccin_mocha"
  2. Copy palette table from:
     https://github.com/catppuccin/starship/tree/main/themes

  Sources:
    btop       https://github.com/catppuccin/btop
    Alacritty  https://github.com/catppuccin/alacritty
    Atuin      https://github.com/catppuccin/atuin
    bat        https://github.com/catppuccin/bat
    cava       https://github.com/catppuccin/cava
    eza        https://github.com/catppuccin/eza
    lazygit    https://github.com/catppuccin/lazygit
    Starship   https://github.com/catppuccin/starship
HELP
        printf "%b" "${COLOR_RESET}"

        ui::return_or_exit
        return
    done
}
