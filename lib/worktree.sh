#!/usr/bin/env bash
# lib/worktree.sh — shared helpers used by all project scripts

# Creates a worktree or jumps to an existing one for the branch.
# Reads git worktree list exactly once to check both cases.
#
# Args: repo_dir worktree_dir branch
# On jump:   writes last-dir, returns 1
# On create: echoes "instance offset", returns 0
_worktree_create() {
    local repo_dir="$1" worktree_dir="$2" branch="$3"

    local porcelain
    porcelain=$(git -C "$repo_dir" worktree list --porcelain)

    local existing
    existing=$(awk -v branch="refs/heads/$branch" '
        /^worktree / { path = $2 }
        /^branch /   && $2 == branch { print path; exit }
    ' <<< "$porcelain")

    if [[ -n "$existing" ]]; then
        success "Worktree already exists at $existing — jumping in"
        _worktree_write_last_dir "$existing"
        return 1
    fi

    local count instance offset
    count=$(grep -c '^worktree ' <<< "$porcelain")
    instance=$(( count + 1 ))
    offset=$(( instance - 1 ))

    # Use the caller's current branch as the base if they're inside this repo
    # (main worktree or any linked worktree), otherwise fall back to repo HEAD.
    local base=""
    local pwd_top
    pwd_top=$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null) || true
    if [[ -n "$pwd_top" ]] && grep -qF "worktree $pwd_top" <<< "$porcelain"; then
        base=$(git -C "$PWD" rev-parse HEAD)
    fi

    step "Creating worktree at $worktree_dir (instance $instance, offset +$offset)"
    if git -C "$repo_dir" show-ref --verify --quiet "refs/heads/$branch"; then
        git -C "$repo_dir" worktree add "$worktree_dir" "$branch" >&2
    else
        git -C "$repo_dir" worktree add -b "$branch" "$worktree_dir" ${base:+"$base"} >&2
    fi

    echo "$instance $offset"
}

# Builds the worktree directory path.
# Args: project_prefix branch
_worktree_dir() {
    echo "$SCORTAIX_PROJECTS_DIR/${1}-${2//\//-}"
}

# Writes the path the shell wrapper will cd to after the command exits.
# Uses SCORTAIX_CALL_ID (set by the wrapper) to avoid collisions between
# concurrent invocations.
# Args: path
_worktree_write_last_dir() {
    echo "$1" > "/tmp/scortaix-last-dir-${SCORTAIX_CALL_ID:-$$}"
}

# Confirmation prompt before a destructive clean.
# Args: worktree_dir branch containers_description
_worktree_confirm_clean() {
    local worktree_dir="$1" branch="$2" containers_description="$3"

    echo -e "${WARN}This will:${NC}"
    echo "  • Stop and remove Docker containers ($containers_description)"
    echo "  • Remove worktree at $worktree_dir"
    echo "  • Delete local branch '$branch'"
    echo ""
    read -r -p "Confirm? [y/N] " confirm
    [[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
}

# Removes the worktree directory and deletes the local branch.
# Args: repo_dir worktree_dir branch
_worktree_finalize_clean() {
    step "Removing worktree"
    git -C "$1" worktree remove "$2" --force

    step "Deleting branch"
    git -C "$1" branch -D "$3"

    success "Done — $2 removed"
    _worktree_write_last_dir "$1"
}
