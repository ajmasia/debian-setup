# bash completion for debian-setup

_debian_setup() {
    local cur prev
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    # After -o/--option, complete with task names
    case "$prev" in
        -o|--option)
            local tasks
            tasks="$(debian-setup --list 2>/dev/null)"
            COMPREPLY=($(compgen -W "$tasks" -- "$cur"))
            return
            ;;
    esac

    # Complete flags
    local flags="-v --version -h --help -s --search -si --search-to-install -sr --search-to-remove -l --list -o --option --update --uninstall"
    COMPREPLY=($(compgen -W "$flags" -- "$cur"))
}

complete -F _debian_setup debian-setup
