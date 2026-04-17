#compdef debian-setup ds

_debian_setup() {
    local -a flags
    flags=(
        '-v:Show version'
        '--version:Show version'
        '-h:Show help'
        '--help:Show help'
        '-s:Start in global search mode'
        '--search:Start in global search mode'
        '-si:Search only available options'
        '--search-to-install:Search only available options'
        '-sr:Search only installed options'
        '--search-to-remove:Search only installed options'
        '-l:List all available tasks'
        '--list:List all available tasks'
        '-o:Jump directly to a task or category'
        '--option:Jump directly to a task or category'
        '--completions:Install shell completions'
        '--update:Update to latest version'
        '--uninstall:Remove debian-setup'
    )

    # After -o/--option, complete from cached task list
    case "${words[CURRENT-1]}" in
        -o|--option)
            local cache="${XDG_CACHE_HOME:-$HOME/.cache}/debian-setup/tasks.txt"
            if [[ -f "$cache" ]]; then
                local -a tasks
                tasks=("${(@f)$(cat "$cache")}")
                compadd -a tasks
            fi
            return
            ;;
    esac

    _describe 'option' flags
}

_debian_setup "$@"
