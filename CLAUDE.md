# scortaix — Claude guidance

## What this is

A bash CLI that manages git worktrees for parallel development across two Scortex projects: **sensei** (the Spark app) and **quality-center**. It solves port collisions and Docker container conflicts when running multiple instances simultaneously.

## Architecture

The entry point `scortaix` is a thin dispatcher. It resolves the project argument and delegates to the relevant project file by sourcing it, then calling the appropriate function.

```
scortaix tree sensei my-feature
  → sources projects/sensei.sh
  → calls sensei_tree "my-feature"
```

Formatting helpers (`step`, `success`, `error`) are defined in `scortaix` and exported so sourced project files can use them.

### Adding a new project

1. Create `projects/<project-name>.sh` following the pattern of existing files
2. Add the project alias to `resolve_project()` in `scortaix`
3. Add the routing cases in the `tree|clean` dispatcher block in `scortaix`
4. Document ports and setup steps in `README.md`

### Adding a new command

1. Add the command to the top-level `case` in `scortaix`
2. Add a `<project>_<command>()` function in each project file
3. Route to it in the project dispatch block

## Key design decisions

**Why bash, not fish?** The scripts are bash so they're shell-agnostic. The `cd` limitation (scripts run in subshells) is handled by a thin shell wrapper installed per-shell by `install.sh`.

**Why source project files instead of calling them as subprocesses?** Sourcing lets project files use the formatting functions (`step`, `success`, `error`) defined in the main script without re-defining them.

**How `cd` works after `scortaix tree`:** The binary writes the target path to `/tmp/scortaix-last-dir`. The shell wrapper (fish function or zsh function, installed by `install.sh`) reads that file and calls `cd` in the current shell after the binary exits.

**Port offset scheme:** Instance number is auto-detected as `(number of existing worktrees) + 1`. Each instance gets all ports shifted by `(instance - 1) * 100`. Instance 1 = main repo with default ports. Instance 2 = offset +100. Etc.

**Docker isolation for sensei:** Container names are explicit (`redis-2`, `postgres-2`) so they don't collide regardless of compose project name.

**Docker isolation for quality-center:** No explicit container names — docker compose auto-namespaces by project name (directory name), which differs per worktree. Cleanup uses `docker compose down` with the PGPORT from `.envrc`.

## Project-specific notes

### sensei (`~/Projects/sensei`)

- Main branch: `spark`
- Worktrees land at: `~/Projects/sensei-<branch>/`
- `.envrc` goes at the worktree root; both `make` and `docker-compose` inherit vars from the shell
- `pnpm-lock.yaml` is at the repo root, so `pnpm install` runs from the worktree root
- `uv sync --inexact --extra ml` (the `--extra ml` is required for ML dependencies)
- After `tree`, user still needs to manually: `cd spark && docker-compose up -d`

### quality-center (`~/Projects/quality-center`)

- Main branch: `main`
- Worktrees land at: `~/Projects/quality-center-<branch>/`
- `.env` must exist (even if empty) because honcho errors if it's missing
- WORKOS credentials are read from the main repo's `.env` at worktree creation time and embedded in `.envrc`
- `pnpm install` runs from `frontend/` subdirectory
- `PGPORT` controls both Django's connection port and the PostgreSQL container's internal port

## What NOT to do

- Do not add project-specific logic to the main `scortaix` file — it stays a dispatcher
- Do not hardcode instance numbers — always auto-detect from `git worktree list | wc -l`
- Do not modify committed project files (sensei, quality-center) — all generated files are gitignored
