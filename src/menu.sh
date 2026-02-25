# Main menu loop

[[ -n "${_MENU_LOADED:-}" ]] && return 0
_MENU_LOADED=1

# All task registries for global search (leaf + mixed arrays)
_SEARCH_ARRAYS=(
    _SYSTEM_TASKS
    _PACKAGES_TASKS
    _SSH_TASKS
    _DOTFILES_TASKS
    _SHELL_TASKS
    _HARDWARE_TASKS
    _VIRTUALIZATION_TASKS
    _DEVELOPMENT_TASKS
    _ENVIRONMENTS_TASKS
    _GIT_TASKS
    _DEVTOOLS_TASKS
    _AI_TASKS
    _SOFTWARE_TASKS
    _EDITORS_TASKS
    _TERMINALS_TASKS
    _BROWSERS_TASKS
    _SECURITY_TASKS
    _VPNS_TASKS
    _PASSWORDS_TASKS
    _AUTHENTICATORS_TASKS
    _HWKEYS_TASKS
    _MEDIA_TASKS
    _MESSAGING_TASKS
    _PRODUCTIVITY_TASKS
    _FONTS_TASKS
    _UI_TASKS
    _APPEARANCE_TASKS
    _APPTHEMES_TASKS
)

# --- Search helpers ---

# Collects leaf tasks into _COLLECTED_LABELS and _COLLECTED_APPLY_FNS arrays.
# Args: filter ("" = all, "available" = not installed, "installed" = installed only)
menu::_collect_leaf_tasks() {
    local filter="${1:-}"
    local arr_name task label desc_var check_fn apply_fn status_fn

    _COLLECTED_LABELS=()
    _COLLECTED_APPLY_FNS=()
    _COLLECTED_TOTAL=0

    for arr_name in "${_SEARCH_ARRAYS[@]}"; do
        local -n tasks_ref="$arr_name"
        for task in "${tasks_ref[@]}"; do
            IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
            [[ "$apply_fn" == *"::run" ]] && continue
            _COLLECTED_TOTAL=$((_COLLECTED_TOTAL + 1))
            if [[ "$filter" == "available" ]]; then
                "$check_fn" && continue
            elif [[ "$filter" == "installed" ]]; then
                "$check_fn" || continue
            fi
            _COLLECTED_LABELS+=("${label#Configure }")
            _COLLECTED_APPLY_FNS+=("$apply_fn")
        done
    done
}

# Routes a selected label to its apply_fn.
menu::_run_choice() {
    local choice="$1"
    local i

    for i in "${!_COLLECTED_LABELS[@]}"; do
        if [[ "${_COLLECTED_LABELS[$i]}" == "$choice" ]]; then
            "${_COLLECTED_APPLY_FNS[$i]}"
            return 0
        fi
    done
    return 1
}

# Prints all available tasks and categories to stdout, sorted alphabetically.
menu::list() {
    menu::_collect_leaf_tasks

    local all=("${_COLLECTED_LABELS[@]}")

    # Include main menu categories
    local entry cat_label cat_fn
    for entry in "${_MENU_CATEGORIES[@]}"; do
        IFS='|' read -r cat_label cat_fn <<< "$entry"
        all+=("$cat_label")
    done

    printf '%s\n' "${all[@]}" | sort -fu
}

# Main menu categories with their run/apply functions.
_MENU_CATEGORIES=(
    "System Essentials|system::run"
    "Package Managers|packages::run"
    "Hardware Support|hardware::run"
    "OpenSSH Server|ssh::run"
    "Git|git_config::apply"
    "Shell Tools|shell::run"
    "Development|development::run"
    "Dotfiles|dotfiles::apply"
    "UI and Theming|ui_module::run"
    "Software|software::run"
    "Virtualization|virtualization::run"
    "Health|diagnostics::run"
)

# Jumps directly to a task or category matching the query.
menu::jump() {
    local query="$1"
    local match_labels=() match_fns=()

    # Collect leaf tasks
    menu::_collect_leaf_tasks
    local i
    for i in "${!_COLLECTED_LABELS[@]}"; do
        local lower_label="${_COLLECTED_LABELS[$i],,}"
        local lower_query="${query,,}"
        if [[ "$lower_label" == *"$lower_query"* ]]; then
            match_labels+=("${_COLLECTED_LABELS[$i]}")
            match_fns+=("${_COLLECTED_APPLY_FNS[$i]}")
        fi
    done

    # Collect categories
    local entry cat_label cat_fn
    for entry in "${_MENU_CATEGORIES[@]}"; do
        IFS='|' read -r cat_label cat_fn <<< "$entry"
        local lower_label="${cat_label,,}"
        local lower_query="${query,,}"
        if [[ "$lower_label" == *"$lower_query"* ]]; then
            # Avoid duplicate if leaf task already matched same name
            local dup=false
            local j
            for j in "${!match_labels[@]}"; do
                [[ "${match_labels[$j]}" == "$cat_label" ]] && dup=true && break
            done
            if ! $dup; then
                match_labels+=("$cat_label")
                match_fns+=("$cat_fn")
            fi
        fi
    done

    local count=${#match_labels[@]}

    if [[ $count -eq 0 ]]; then
        log::error "No match found for '${query}'"
        exit 1
    elif [[ $count -eq 1 ]]; then
        "${match_fns[0]}"
        ui::clear_content
        ui::goodbye
    else
        # Multiple matches — let user pick
        local choice
        local items=("${match_labels[@]}" "Exit")

        choice="$(gum::filter \
            --height 20 \
            --header "Multiple matches for '${query}' (${count}):" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to filter..." \
            "${items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local k
                for k in "${!match_labels[@]}"; do
                    if [[ "${match_labels[$k]}" == "$choice" ]]; then
                        "${match_fns[$k]}"
                        ui::clear_content
                        ui::goodbye
                    fi
                done
                ;;
        esac
    fi
}

# --- Main menu ---

menu::main() {
    local choice items

    while true; do
        items=("System Essentials" "Package Managers" "Hardware Support" "OpenSSH Server" "Git" "Shell Tools" "Development" "Dotfiles" "UI and Theming" "Software" "Virtualization" "Health" "Exit")

        choice="$(gum::filter \
            --height 15 \
            --header "Select an option:" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to filter..." \
            "${items[@]}")"

        case "$choice" in
            "Hardware Support")
                hardware::run
                ui::clear_content
                ;;
            "Package Managers")
                packages::run
                ui::clear_content
                ;;
            "System Essentials")
                system::run
                ui::clear_content
                ;;
            "Dotfiles")
                dotfiles::apply
                ui::clear_content
                ;;
            "Shell Tools")
                shell::run
                ui::clear_content
                ;;
            "OpenSSH Server")
                ssh::run
                ui::clear_content
                ;;
            "Git")
                git_config::apply
                ui::clear_content
                ;;
            "Development")
                development::run
                ui::clear_content
                ;;
            "UI and Theming")
                ui_module::run
                ui::clear_content
                ;;
            "Software")
                software::run
                ui::clear_content
                ;;
            "Virtualization")
                virtualization::run
                ui::clear_content
                ;;
            "Health")
                diagnostics::run
                ui::clear_content
                ;;
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
        esac
    done
}

menu::search() {
    local choice

    while true; do
        ui::clear_content
        menu::_collect_leaf_tasks

        local items=("${_COLLECTED_LABELS[@]}" "Exit")
        local header="Search all options (${#_COLLECTED_APPLY_FNS[@]}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                menu::_run_choice "$choice"
                ui::clear_content
                ;;
        esac
    done
}

menu::search_to_install() {
    local choice

    while true; do
        ui::clear_content

        ui::spin_start "Loading data..."
        menu::_collect_leaf_tasks "available"
        ui::spin_stop

        local items=("${_COLLECTED_LABELS[@]}" "Exit")
        local header="Available to install (${#_COLLECTED_APPLY_FNS[@]}/${_COLLECTED_TOTAL}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                menu::_run_choice "$choice"
                ui::clear_content
                ;;
        esac
    done
}

menu::search_to_remove() {
    local choice

    while true; do
        ui::clear_content

        ui::spin_start "Loading data..."
        menu::_collect_leaf_tasks "installed"
        ui::spin_stop

        local items=("${_COLLECTED_LABELS[@]}" "Exit")
        local header="Installed (${#_COLLECTED_APPLY_FNS[@]}/${_COLLECTED_TOTAL}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                menu::_run_choice "$choice"
                ui::clear_content
                ;;
        esac
    done
}
