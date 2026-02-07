# OpenPGP tools task

[[ -n "${_MOD_OPENPGP_LOADED:-}" ]] && return 0
_MOD_OPENPGP_LOADED=1

_OPENPGP_LABEL="Configure OpenPGP"
_OPENPGP_DESC="Install OpenPGP tools."
_OPENPGP_LIST="${SCRIPT_DIR}/packages/apt/openpgp.txt"

openpgp::check() { apt::list_check "$_OPENPGP_LIST"; }

openpgp::status() { apt::list_status "$_OPENPGP_LIST"; }

openpgp::apply() {
    apt::list_wizard "Software > Security > OpenPGP" \
        "OpenPGP tools" "$_OPENPGP_LIST"
}
