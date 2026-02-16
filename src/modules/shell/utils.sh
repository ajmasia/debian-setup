# CLI utilities task

[[ -n "${_MOD_UTILS_LOADED:-}" ]] && return 0
_MOD_UTILS_LOADED=1

_UTILS_LABEL="Configure Utilities"
_UTILS_DESC="Install common CLI utilities."
_UTILS_LIST="${SCRIPT_DIR}/packages/apt/utils.txt"

utils::check() { apt::list_check "$_UTILS_LIST"; }

utils::status() { apt::list_status "$_UTILS_LIST"; }

utils::apply() {
    apt::list_wizard "Shell Tools > Utilities" \
        "CLI utilities packages" "$_UTILS_LIST"
}
