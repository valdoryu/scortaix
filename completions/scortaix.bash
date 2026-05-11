# bash completion for scortaix

_scortaix() {
    local cur words cword
    if declare -f _init_completion > /dev/null 2>&1; then
        _init_completion || return
    else
        COMPREPLY=()
        cur="${COMP_WORDS[COMP_CWORD]}"
        words=("${COMP_WORDS[@]}")
        cword=$COMP_CWORD
    fi

    case $cword in
        1)
            COMPREPLY=($(compgen -W "tree clean uninstall help" -- "$cur"))
            ;;
        2)
            case "${words[1]}" in
                tree|clean)
                    COMPREPLY=($(compgen -W "sensei scortex quality-center qc" -- "$cur"))
                    ;;
            esac
            ;;
        3)
            case "${words[1]}" in
                tree|clean)
                    local project
                    case "${words[2]}" in
                        sensei|scortex)     project="sensei" ;;
                        quality-center|qc)  project="quality-center" ;;
                        *)                  return ;;
                    esac
                    local config="${XDG_CONFIG_HOME:-$HOME/.config}/scortaix/config"
                    if [[ -f "$config" ]]; then
                        local SCORTAIX_PROJECTS_DIR SCORTAIX_SOURCE_DIR
                        # shellcheck disable=SC1090
                        source "$config"
                        local repo_dir="${SCORTAIX_PROJECTS_DIR}/${project}"
                        if [[ -d "$repo_dir" ]]; then
                            local branches
                            branches=$(git -C "$repo_dir" branch --format='%(refname:short)' 2>/dev/null)
                            COMPREPLY=($(compgen -W "$branches" -- "$cur"))
                        fi
                    fi
                    ;;
            esac
            ;;
    esac
}

complete -F _scortaix scortaix
