# AI Resources task (informational)

[[ -n "${_MOD_AIRESOURCES_LOADED:-}" ]] && return 0
_MOD_AIRESOURCES_LOADED=1

_AIRESOURCES_LABEL="AI Resources"
_AIRESOURCES_DESC="Browse curated AI resources for development."

# Always OK — informational only
airesources::check() { return 0; }
airesources::status() { :; }

# Resource entries: "name|category|description|url"
_AIRESOURCES_LIST=(
    "Cursor|Editor|AI-first code editor built on VS Code|https://cursor.com"
    "v0|Web Dev|AI UI generator by Vercel (React/Next.js)|https://v0.dev"
    "Bolt|Web Dev|AI full-stack web app generator|https://bolt.new"
    "Aider|Python|AI pair programming in the terminal|https://aider.chat"
    "Open Interpreter|Python|Natural language interface for your computer|https://openinterpreter.com"
    "Ollama|Local AI|Run LLMs locally|https://ollama.com"
    "LM Studio|Local AI|Desktop app for running local LLMs|https://lmstudio.ai"
    "OpenRouter|API|Unified API for multiple LLM providers|https://openrouter.ai"
    "Continue|Editor|Open-source AI code assistant for VS Code/JetBrains|https://continue.dev"
    "Cody|Editor|AI coding assistant by Sourcegraph|https://sourcegraph.com/cody"
)

airesources::apply() {
    local choice

    while true; do
        ui::clear_content
        log::nav "Development > AI > AI Resources"
        log::break

        log::info "Curated AI resources for development"
        log::break

        # Build display items
        local items=() names=()
        local entry name category desc url
        for entry in "${_AIRESOURCES_LIST[@]}"; do
            IFS='|' read -r name category desc url <<< "$entry"
            items+=("${name} (${category})")
            names+=("$name")
        done
        items+=("Back" "Exit")

        choice="$(gum::filter \
            --height 12 \
            --header "Select a resource for details:" \
            --header.foreground "$HEX_LAVENDER" \
            --indicator.foreground "$HEX_BLUE" \
            --text.foreground "$HEX_TEXT" \
            --cursor-text.foreground "$HEX_GREEN" \
            --match.foreground "$HEX_MAUVE" \
            --placeholder "Type to filter..." \
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
                # Find matching entry
                local i
                for i in "${!items[@]}"; do
                    if [[ "${items[$i]}" == "$choice" ]]; then
                        IFS='|' read -r name category desc url <<< "${_AIRESOURCES_LIST[$i]}"
                        log::break
                        log::info "${name}"
                        log::ok "Category: ${category}"
                        log::ok "Description: ${desc}"
                        log::ok "URL: ${url}"
                        log::break

                        gum::choose \
                            --header "Press Enter to continue" \
                            --header.foreground "$HEX_LAVENDER" \
                            --cursor.foreground "$HEX_BLUE" \
                            --item.foreground "$HEX_TEXT" \
                            --selected.foreground "$HEX_GREEN" \
                            "OK" > /dev/null
                        break
                    fi
                done
                ;;
        esac
    done
}
