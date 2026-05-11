# scortaix

CLI for managing parallel git worktrees across Scortex projects. Lets multiple Claude Code instances (or developers) work on different features simultaneously without port collisions or shared Docker containers.

## Install

```bash
cd ~/Projects/scortaix
bash install.sh
```

The installer will:

1. Copy the `scortaix` binary to `~/.local/bin/scortaix`
2. Ask which shell you use (fish, zsh, or bash)
3. Install a shell wrapper function that handles `cd` after `scortaix tree`
4. Install tab completions for commands, projects, and branches

Reload your shell after installing.

## Commands

### `scortaix tree <project> <branch>`

Creates a new worktree for the given branch and jumps into it. If a worktree for that branch already exists, jumps into it directly.

```bash
scortaix tree sensei my-feature
scortaix tree qc fix/login-bug
```

What it does:

- Creates the worktree at `~/Projects/<project>-<branch>/`
- Writes a `.envrc` with isolated ports (offset by instance number)
- Runs `uv sync`, `pnpm install`, `pre-commit install`, `git config`
- Runs `direnv allow`
- `cd`s into the new worktree

### `scortaix clean <project> <branch>`

Removes a worktree and cleans up everything associated with it. Asks for confirmation first.

```bash
scortaix clean sensei my-feature
scortaix clean qc fix/login-bug
```

What it does:

- Stops and removes Docker containers for that instance
- Removes the worktree directory
- Deletes the local git branch

## Project aliases

| Alias                  | Project                     |
| ---------------------- | --------------------------- |
| `sensei`, `scortex`    | `~/Projects/sensei`         |
| `quality-center`, `qc` | `~/Projects/quality-center` |

## Port isolation

Each worktree gets a unique instance number (auto-detected from existing worktrees). All ports are offset by 1, except for sensei cameras which are incremented by 4 because there are four of them.

**sensei** — instance 2 example:

| Service    | Default   | Instance 2 |
| ---------- | --------- | ---------- |
| Flask      | 5000      | 5001       |
| WebSocket  | 12321     | 12322      |
| Camera WS  | 4000-4003 | 4004-4007  |
| Vite dev   | 3000      | 3001       |
| PostgreSQL | 5432      | 5433       |
| Redis      | 6379      | 6380       |
| Adminer    | 8080      | 8081       |

**quality-center** — instance 2 example:

| Service    | Default | Instance 2 |
| ---------- | ------- | ---------- |
| Django     | 8000    | 8001       |
| Vite dev   | 5173    | 5174       |
| PostgreSQL | 55432   | 55433      |

## How `cd` works

Bash scripts run in a subshell and cannot change the parent shell's directory. The workaround: the `scortaix` binary writes the target path to `/tmp/scortaix-last-dir` at the end of `tree`, and the shell wrapper function (installed by `install.sh`) reads it and calls `cd` in the current shell.

## Tab completions

Completions are installed automatically by `install.sh` for your shell:

| Shell | Completion file |
| ----- | --------------- |
| fish  | `~/.config/fish/completions/scortaix.fish` |
| zsh   | `~/.local/share/zsh/site-functions/_scortaix` |
| bash  | `~/.local/share/bash-completion/completions/scortaix` |

All three complete `tree`/`clean` → project → branch (branches are resolved live from the project's git repo).

## File structure

```
scortaix/
  scortaix              # Main dispatcher — parses command + project, sources the right file
  install.sh            # Installs binary, shell wrapper, and completions
  projects/
    sensei.sh           # sensei tree/clean logic
    quality-center.sh   # quality-center tree/clean logic
  completions/
    scortaix.bash       # bash completion script
    scortaix.fish       # fish completion script
    _scortaix           # zsh completion script
  README.md
  CLAUDE.md
```
