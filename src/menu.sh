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
    _MESSAGING_TASKS
    _PRODUCTIVITY_TASKS
    _FONTS_TASKS
    _UI_TASKS
    _APPEARANCE_TASKS
    _APPTHEMES_TASKS
)

menu::main() {
    local choice items

    while true; do
        items=("System Essentials" "Hardware Support" "Package Managers" "Dotfiles" "Shell Tools" "OpenSSH Server" "Development" "UI and Theming" "Software" "Virtualization" "Health" "Exit")

        choice="$(gum::filter \
            --height 14 \
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

        # Collect all leaf tasks from all registries
        local all_items=() all_apply_fns=()
        local arr_name task label desc_var check_fn apply_fn status_fn

        for arr_name in "${_SEARCH_ARRAYS[@]}"; do
            local -n tasks_ref="$arr_name"
            for task in "${tasks_ref[@]}"; do
                IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
                # Skip sub-aggregators (::run), only include leaf tasks (::apply)
                [[ "$apply_fn" == *"::run" ]] && continue
                all_items+=("${label#Configure }")
                all_apply_fns+=("$apply_fn")
            done
        done

        all_items+=("Exit")
        local header="Search all options (${#all_apply_fns[@]}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${all_items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local i
                for i in "${!all_items[@]}"; do
                    if [[ "${all_items[$i]}" == "$choice" ]]; then
                        "${all_apply_fns[$i]}"
                        ui::clear_content
                        break
                    fi
                done
                ;;
        esac
    done
}

menu::search_to_install() {
    local choice

    while true; do
        ui::clear_content

        # Collect non-installed leaf tasks from all registries
        local all_items=() all_apply_fns=() total=0
        local arr_name task label desc_var check_fn apply_fn status_fn

        ui::spin_start "Loading data..."
        for arr_name in "${_SEARCH_ARRAYS[@]}"; do
            local -n tasks_ref="$arr_name"
            for task in "${tasks_ref[@]}"; do
                IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
                [[ "$apply_fn" == *"::run" ]] && continue
                total=$((total + 1))
                # Skip already installed (check_fn returns 0)
                "$check_fn" && continue
                all_items+=("${label#Configure }")
                all_apply_fns+=("$apply_fn")
            done
        done
        ui::spin_stop

        all_items+=("Exit")
        local header="Available to install (${#all_apply_fns[@]}/${total}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${all_items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local i
                for i in "${!all_items[@]}"; do
                    if [[ "${all_items[$i]}" == "$choice" ]]; then
                        "${all_apply_fns[$i]}"
                        ui::clear_content
                        break
                    fi
                done
                ;;
        esac
    done
}

menu::search_to_remove() {
    local choice

    while true; do
        ui::clear_content

        # Collect installed leaf tasks from all registries
        local all_items=() all_apply_fns=() total=0
        local arr_name task label desc_var check_fn apply_fn status_fn

        ui::spin_start "Loading data..."
        for arr_name in "${_SEARCH_ARRAYS[@]}"; do
            local -n tasks_ref="$arr_name"
            for task in "${tasks_ref[@]}"; do
                IFS='|' read -r label desc_var check_fn apply_fn status_fn <<< "$task"
                [[ "$apply_fn" == *"::run" ]] && continue
                total=$((total + 1))
                # Skip not installed (check_fn returns non-zero)
                "$check_fn" || continue
                all_items+=("${label#Configure }")
                all_apply_fns+=("$apply_fn")
            done
        done
        ui::spin_stop

        all_items+=("Exit")
        local header="Installed (${#all_apply_fns[@]}/${total}):"

        choice="$(gum::filter \
            --height 20 \
            --header "$header" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to search..." \
            "${all_items[@]}")"

        case "$choice" in
            ""|"Exit")
                ui::clear_content
                ui::goodbye
                ;;
            *)
                local i
                for i in "${!all_items[@]}"; do
                    if [[ "${all_items[$i]}" == "$choice" ]]; then
                        "${all_apply_fns[$i]}"
                        ui::clear_content
                        break
                    fi
                done
                ;;
        esac
    done
}
