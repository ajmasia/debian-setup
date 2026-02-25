# Browser themes task (informational)

[[ -n "${_MOD_BROWSERTHEMES_LOADED:-}" ]] && return 0
_MOD_BROWSERTHEMES_LOADED=1

_BROWSERTHEMES_LABEL="Browser Themes"
_BROWSERTHEMES_DESC="Catppuccin Mocha theme install guide for browsers."

# Always OK — informational only
browserthemes::check() { return 0; }
browserthemes::status() { :; }

browserthemes::apply() {
    ui::clear_content
    log::nav "UI > Browser Themes"
    log::break

    log::info "Catppuccin Mocha — Browser themes"
    log::break

    printf "%b" "${COLOR_OVERLAY1}"
    cat <<'HELP'
  Brave / Chromium (Chrome Web Store)
  ────────────────────────────────────
  1. Open the Chrome Web Store link below in your browser
  2. Click "Add to Chrome" / "Add to Brave"

     https://chromewebstore.google.com/detail/
       catppuccin-chrome-theme-m/bkkmolkhemgaeaeggcmfbghljjjoofoh

  Manual install (alternative):
  1. Download .crx from GitHub releases:
     https://github.com/catppuccin/chrome/releases/latest
  2. Go to chrome://extensions
  3. Enable "Developer mode"
  4. Drag and drop the .crx file or "Load unpacked"

  Firefox / LibreWolf (Firefox Color)
  ────────────────────────────────────
  1. Install the Firefox Color addon:
     https://addons.mozilla.org/en-US/firefox/addon/firefox-color/
  2. Pick your accent color from the repo and click the link:
     https://github.com/catppuccin/firefox

  Available accent colors:
    Rosewater, Flamingo, Pink, Mauve, Red, Maroon, Peach,
    Yellow, Green, Teal, Sky, Sapphire, Blue, Lavender

  Sources:
    Chrome/Brave  https://github.com/catppuccin/chrome
    Firefox       https://github.com/catppuccin/firefox
HELP
    printf "%b" "${COLOR_RESET}"

    ui::return_or_exit
}
