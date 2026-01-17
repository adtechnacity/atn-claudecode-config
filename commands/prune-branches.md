---
description: Prune old and merged feature branches. Safely removes local and remote branches after merge.
---

# Prune Merged Branches

Safely identify and remove git branches that have been merged into the base branch.

**SAFETY**: Dry-run by default. Use `--execute` to actually delete branches.

## Integration

Can be run standalone or as part of repository maintenance.
Related: `/cleanup`, `/rollback`

## Options

- `--execute` - Actually delete branches (default is dry-run)
- `--local-only` - Only prune local branches
- `--remote-only` - Only prune remote branches
- `--exclude <pattern>` - Additional branch patterns to protect

## Workflow

### Step 1: Fetch Latest State

```bash
git fetch --prune
```

### Step 2: Detect Base Branch

Auto-detect the default branch (main or master):

```bash
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
if [ -z "$BASE" ]; then
  # Fallback: check which exists
  if git show-ref --verify --quiet refs/heads/main; then
    BASE="main"
  else
    BASE="master"
  fi
fi
```

### Step 3: Identify Merged Branches

**Protected branches (never delete):**
- main, master, develop, staging, production
- Current branch (the one you're on)
- Any branch matching user-provided `--exclude` pattern

**Find merged local branches:**
```bash
git branch --merged $BASE | grep -vE '^\*|^\s*(main|master|develop|staging|production)\s*$'
```

**Find merged remote branches:**
```bash
git branch -r --merged origin/$BASE | grep -vE 'origin/(main|master|develop|staging|production|HEAD)'
```

### Step 4: Display Candidates

Show all branches that would be deleted:

```markdown
## Branches to Prune

### Local Branches
- feature/old-feature
- fix/completed-bugfix

### Remote Branches
- origin/feature/old-feature
- origin/fix/completed-bugfix

Total: X local, Y remote branches
```

### Step 5: Execute (if --execute flag)

If `--execute` was NOT provided:
- Display the candidates only
- Remind user to run with `--execute` to delete

If `--execute` WAS provided:
- Confirm with user before proceeding
- Delete local branches: `git branch -d <branch>`
- Delete remote branches: `git push origin --delete <branch>`
- Report results

### Step 6: Report

```markdown
## Prune Results

### Deleted
- Local: X branches
- Remote: Y branches

### Skipped (protected)
- main, develop, etc.

### Errors (if any)
- [branch]: [error message]
```

## Safety Protocols

1. **Dry-run default** - Shows candidates without deleting unless `--execute` is used
2. **Protected branches** - main, master, develop, staging, production are never deleted
3. **Current branch** - Never deletes the branch you're currently on
4. **Merge verification** - Only deletes branches confirmed merged via `git branch --merged`
5. **Confirmation** - Asks for confirmation before deleting when using `--execute`
