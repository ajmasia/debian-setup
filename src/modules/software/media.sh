# Media tools software task

[[ -n "${_MOD_MEDIA_LOADED:-}" ]] && return 0
_MOD_MEDIA_LOADED=1

_MEDIA_LABEL="Configure Media"
_MEDIA_DESC="Install media players, codecs and tools."
_MEDIA_LIST="${SCRIPT_DIR}/packages/apt/media.txt"

media::check() { apt::list_check "$_MEDIA_LIST"; }

media::status() { apt::list_status "$_MEDIA_LIST"; }

media::apply() {
    apt::list_wizard "Software > Configure Media" \
        "Media tools & codecs packages" "$_MEDIA_LIST"
}
