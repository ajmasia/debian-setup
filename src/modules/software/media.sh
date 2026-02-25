# Media sub-aggregator

[[ -n "${_MOD_MEDIA_LOADED:-}" ]] && return 0
_MOD_MEDIA_LOADED=1

_MEDIA_LABEL="Configure Media"
_MEDIA_DESC="Install media players, codecs and tools."

_MEDIA_APT_LABEL="Configure Media Packages"
_MEDIA_APT_DESC="Install media players, codecs and tools."
_MEDIA_APT_LIST="${SCRIPT_DIR}/packages/apt/media.txt"

_media_apt::check() { apt::list_check "$_MEDIA_APT_LIST"; }
_media_apt::status() { apt::list_status "$_MEDIA_APT_LIST"; }
_media_apt::apply() {
    apt::list_wizard "Software > Media > Media Packages" \
        "Media tools & codecs packages" "$_MEDIA_APT_LIST"
}

_MEDIA_TASKS=(
    "${_MEDIA_APT_LABEL}|_MEDIA_APT_DESC|_media_apt::check|_media_apt::apply|_media_apt::status"
    "${_SPOTIFY_LABEL}|_SPOTIFY_DESC|spotify::check|spotify::apply|spotify::status"
)

media::check() {
    local task
    for task in "${_MEDIA_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || return 1
    done
}

media::status() {
    local pending=0
    local task
    for task in "${_MEDIA_TASKS[@]}"; do
        IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
        "$check_fn" || pending=$((pending + 1))
    done
    [[ $pending -gt 0 ]] && printf '%s items pending' "$pending"
}

media::run() {
    local task label desc_var check_fn apply_fn status_fn choice

    while true; do
        ui::clear_content
        log::nav "Software > Media"
        log::break

        local items=() apply_fns=()
        for task in "${_MEDIA_TASKS[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            items+=("${label#Configure }")
            apply_fns+=("$apply_fn")
        done
        items+=("Back" "Exit")

        choice="$(gum::choose \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --cursor.foreground "$HEX_BLUE" \
            --item.foreground "$HEX_TEXT" \
            --selected.foreground "$HEX_GREEN" \
            "${items[@]}")"

        case "$choice" in
            ""|"Back")
                return
                ;;
            "Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local i
                for i in "${!items[@]}"; do
                    if [[ "${items[$i]}" == "$choice" ]]; then
                        "${apply_fns[$i]}"
                        break
                    fi
                done
                ;;
        esac
    done
}
