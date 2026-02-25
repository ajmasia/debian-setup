# bash completion for debian-setup

_debian_setup() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # After -o/--option, complete from cached task list
    case "$prev" in
        -o|--option)
            local cache="${XDG_CACHE_HOME:-$HOME/.cache}/debian-setup/tasks.txt"
            if [[ -f "$cache" ]]; then
                local IFS=$'\n'
                mapfile -t COMPREPLY < <(grep -i -- "^${cur}" "$cache")
            fi
            return
            ;;
    esac

    # Complete flags
    COMPREPLY=($(compgen -W "-v --version -h --help -s --search -si --search-to-install -sr --search-to-remove -l --list -o --option --update --uninstall" -- "$cur"))
}

complete -F _debian_setup debian-setup
