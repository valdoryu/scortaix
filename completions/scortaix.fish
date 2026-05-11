# fish completions for scortaix

function __scortaix_no_subcommand
    not __fish_seen_subcommand_from tree clean uninstall help
end

function __scortaix_needs_project
    __fish_seen_subcommand_from tree clean
    and not __fish_seen_subcommand_from sensei scortex quality-center qc
end

function __scortaix_branches
    set -l project $argv[1]
    set -l config "$HOME/.config/scortaix/config"
    test -n "$XDG_CONFIG_HOME"; and set config "$XDG_CONFIG_HOME/scortaix/config"
    test -f $config; or return
    set -l projects_dir (grep '^SCORTAIX_PROJECTS_DIR=' $config | cut -d= -f2 | tr -d '"')
    test -d "$projects_dir/$project"; or return
    git -C "$projects_dir/$project" branch --format='%(refname:short)' 2>/dev/null
end

# Commands
complete -c scortaix -f -n __scortaix_no_subcommand -a tree       -d 'Create or jump to a worktree'
complete -c scortaix -f -n __scortaix_no_subcommand -a clean      -d 'Remove a worktree and its containers'
complete -c scortaix -f -n __scortaix_no_subcommand -a uninstall  -d 'Remove binary and shell wrappers'
complete -c scortaix -f -n __scortaix_no_subcommand -a help       -d 'Show usage'

# Projects
complete -c scortaix -f -n __scortaix_needs_project -a sensei         -d 'Sensei / Spark app'
complete -c scortaix -f -n __scortaix_needs_project -a scortex        -d 'Sensei (alias)'
complete -c scortaix -f -n __scortaix_needs_project -a quality-center -d 'Quality Center'
complete -c scortaix -f -n __scortaix_needs_project -a qc             -d 'Quality Center (alias)'

# Branches — resolved dynamically per project
complete -c scortaix -f \
    -n '__fish_seen_subcommand_from tree clean; and __fish_seen_subcommand_from sensei scortex' \
    -a '(__scortaix_branches sensei)'

complete -c scortaix -f \
    -n '__fish_seen_subcommand_from tree clean; and __fish_seen_subcommand_from quality-center qc' \
    -a '(__scortaix_branches quality-center)'
