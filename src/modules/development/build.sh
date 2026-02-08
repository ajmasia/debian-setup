# Build essentials developer tool task

[[ -n "${_MOD_BUILD_LOADED:-}" ]] && return 0
_MOD_BUILD_LOADED=1

_BUILD_LABEL="Configure Build Essentials"
_BUILD_DESC="Install core compilation tools and development libraries."
_BUILD_LIST="${SCRIPT_DIR}/packages/apt/build.txt"

build::check() { apt::list_check "$_BUILD_LIST"; }

build::status() { apt::list_status "$_BUILD_LIST"; }

build::apply() {
    apt::list_wizard "Development > Tools > Build Essentials" \
        "Build essentials packages" "$_BUILD_LIST"
}
