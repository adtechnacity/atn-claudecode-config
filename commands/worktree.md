---
description: Create and manage git worktrees for parallel feature development
argument-hint: [branch-name | list | remove <name> | cleanup]
---

Create and manage git worktrees for parallel feature development. Replaces Conductor — after creation, open a new terminal, `cd` into the path, and run `claude`.

## Argument Routing

| Argument | Action |
|----------|--------|
| `<branch-name>` | Create worktree + setup + report path |
| (no args) or `list` | List all active worktrees with status |
| `remove <name>` | Remove worktree (with safety checks) |
| `cleanup` | Batch remove worktrees for merged branches |

Parse `$ARGUMENTS` and route to the matching section below.

---

## Create Flow

### Step 1: Detect Repo

```bash
git rev-parse --show-toplevel
```

Extract the project name from the toplevel path (basename).

### Step 2: Resolve Branch

Check if the branch already exists:

```bash
git branch --list "<branch-name>"
git ls-remote --heads origin "<branch-name>"
```

- **New branch (doesn't exist anywhere):** Will create from current HEAD.
- **Exists locally:** Ask user — reuse existing branch or create fresh from HEAD?
- **Exists on remote only:** Ask user — track remote branch or create fresh from HEAD?

### Step 3: Determine Directory Location

Check in priority order:

1. If `.worktrees/` or `worktrees/` directory exists at repo root, use it (verify it's in `.gitignore`)
2. **Default:** `../<project>--<branch-sanitized>` (slashes → dashes, e.g. `feat/new-api` → `project--feat-new-api`)

```bash
# Sanitize branch name for directory
SANITIZED=$(echo "<branch-name>" | tr '/' '-')
WORKTREE_PATH="../<project>--${SANITIZED}"
```

### Step 4: Create Worktree

```bash
# New branch:
git worktree add "<path>" -b "<branch-name>"

# Existing branch:
git worktree add "<path>" "<branch-name>"
```

### Step 5: Project Setup

Auto-detect build system and install dependencies in the new worktree:

| Indicator | Setup Command |
|-----------|---------------|
| `package.json` + lockfile | `npm ci` (or `npm install` if no lockfile) |
| `mix.exs` | `mix deps.get` |
| `Cargo.toml` | `cargo fetch` |
| `pyproject.toml` | `poetry install` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.mod` | `go mod download` |

Run the matching command inside the worktree directory. Skip if no indicator found.

### Step 6: Baseline Tests

**ASK USER** (use AskUserQuestion):
- Header: "Tests"
- Question: "Run baseline tests in the new worktree to verify clean starting state?"
- Options:
  - **Run tests** — Run test suite and report results
  - **Skip tests** — Trust the base branch is green

If user chooses to run tests, detect and run:

| Indicator | Test Command |
|-----------|--------------|
| `package.json` | `npm test` |
| `mix.exs` | `mix test` |
| `Cargo.toml` | `cargo test` |
| `pyproject.toml` | `pytest` |
| `go.mod` | `go test ./...` |

If tests fail, warn and ask:
- **Continue anyway** — Proceed with worktree (tests were already failing on base)
- **Abort** — Remove the worktree and stop

### Step 7: Copy CLAUDE.md

If a project-level `CLAUDE.md` exists at the repo root, copy it into the worktree root:

```bash
cp "<repo-root>/CLAUDE.md" "<worktree-path>/CLAUDE.md" 2>/dev/null || true
```

### Step 8: Report

Display a summary:

```
Worktree created:
  Branch:  <branch-name>
  Path:    <worktree-path>
  Deps:    installed (npm ci)
  Tests:   passed | skipped | failed (continued)

Next steps:
  cd <worktree-path> && claude
```

---

## List Flow

```bash
git worktree list
```

Format as a table. For each worktree, show:
- Path
- Branch name
- Clean/dirty status (run `git -C <path> status --porcelain` for each)

---

## Remove Flow

### Step 1: Validate Target

Resolve the worktree path from the name argument. Check it exists in `git worktree list`.

### Step 2: Safety Check

```bash
git -C "<worktree-path>" status --porcelain
```

If there are uncommitted changes, **warn the user** and show the dirty files.

### Step 3: Confirm

**ASK USER** (use AskUserQuestion):
- Header: "Remove"
- Question: "Remove worktree at `<path>`? The branch `<branch>` will be preserved."
- Options:
  - **Remove worktree** — Remove the working directory (branch is kept)
  - **Cancel** — Keep the worktree

### Step 4: Execute

```bash
git worktree remove "<worktree-path>"
```

If it fails due to uncommitted changes and user insists:
```bash
git worktree remove --force "<worktree-path>"
```

### Step 5: Report

```
Worktree removed: <path>
Branch preserved: <branch-name>

To delete the branch: git branch -d <branch-name>
```

---

## Cleanup Flow

### Step 1: Find Merged Worktrees

Determine base branch (main or master), then find worktrees whose branches are fully merged:

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git worktree list --porcelain
git branch --merged "$BASE"
```

Cross-reference: worktrees whose branch appears in the merged list are candidates.

### Step 2: Show Candidates

Display a table of worktrees eligible for removal (path, branch, merged status).

If no candidates found, report "No merged worktrees to clean up." and stop.

### Step 3: Confirm

**ASK USER** (use AskUserQuestion):
- Header: "Cleanup"
- Question: "Remove these merged worktrees? Branches will also be deleted."
- Options:
  - **Remove all** — Clean up all listed worktrees and branches
  - **Pick individually** — Choose which to remove
  - **Cancel** — Keep everything

### Step 4: Execute

For each confirmed worktree:
```bash
git worktree remove "<path>"
git branch -d "<branch>"
```

### Step 5: Report

Summary of removed worktrees and branches.

---

## Integration

**Pairs with:** `finishing-a-development-branch` (handles the "finish" side — merge, PR, cleanup)

**Complements:** `/prune-branches` (prunes branches; `/worktree cleanup` prunes worktrees)

**Lifecycle:** `/worktree <branch>` → develop → `/commit` → `/pr` or `/ship` → `finishing-a-development-branch` → `/worktree remove`
