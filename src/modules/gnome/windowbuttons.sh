# Window button layout configuration

[[ -n "${_MOD_WINDOWBUTTONS_LOADED:-}" ]] && return 0
_MOD_WINDOWBUTTONS_LOADED=1

_WINDOWBUTTONS_LABEL="Configure Window Buttons"
_WINDOWBUTTONS_DESC="Configure window button layout and position."

_WINDOWBUTTONS_KEY="org.gnome.desktop.wm.preferences"
_WINDOWBUTTONS_DEFAULT="appmenu:close"

_windowbuttons::get_layout() {
    gsettings get "$_WINDOWBUTTONS_KEY" button-layout 2>/dev/null | tr -d "'"
}

_windowbuttons::is_default() {
    local current
    current="$(_windowbuttons::get_layout)"
    [[ "$current" == "$_WINDOWBUTTONS_DEFAULT" ]]
}

windowbuttons::check() {
    ! _windowbuttons::is_default
}

windowbuttons::status() {
    _windowbuttons::is_default && printf 'default layout'
}

windowbuttons::apply() {
    local choice

    while true; do
        local current
        current="$(_windowbuttons::get_layout)"

        ui::clear_content
        log::nav "GNOME > Appearance > Window Buttons"
        log::break

        log::info "Window button layout"
        log::ok "Current: ${current}"
        log::break

        choice="$(gum::choose \
            --header "Select a layout:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "Right: close (default)" \
            "Right: minimize, maximize, close" \
            "Left: close, minimize, maximize" \
            "Custom" \
            "Back" "Exit")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            "Right: close (default)")
                log::break
                gsettings set "$_WINDOWBUTTONS_KEY" button-layout 'appmenu:close' || true
                log::ok "Layout applied: appmenu:close"
                ;;
            "Right: minimize, maximize, close")
                log::break
                gsettings set "$_WINDOWBUTTONS_KEY" button-layout 'appmenu:minimize,maximize,close' || true
                log::ok "Layout applied: appmenu:minimize,maximize,close"
                ;;
            "Left: close, minimize, maximize")
                log::break
                gsettings set "$_WINDOWBUTTONS_KEY" button-layout 'close,minimize,maximize:appmenu' || true
                log::ok "Layout applied: close,minimize,maximize:appmenu"
                ;;
            "Custom")
                log::break
                local layout
                layout="$(gum::input \
                    --header "Enter button layout:" \
                    --header.foreground "$HEX_LAVENDER" \
                    --cursor.foreground "$HEX_BLUE" \
                    --placeholder "e.g. close,minimize:maximize" \
                    --value "$current")"

                if [[ -z "$layout" ]]; then
                    continue
                fi

                gsettings set "$_WINDOWBUTTONS_KEY" button-layout "$layout" || true
                log::ok "Layout applied: ${layout}"
                ;;
        esac
    done
}
