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

### Step 3.5: Verify Release Branches

**IMPORTANT**: Before suggesting release branches for deletion, verify they have been properly released.

For each branch matching `release/*` or `release-*` pattern:

1. **Extract version** from branch name (e.g., `release/v1.2.0` → `v1.2.0`)

2. **Check for corresponding tag:**
   ```bash
   git tag -l "v1.2.0" "1.2.0"  # Check both with and without 'v' prefix
   ```

3. **Check for GitHub release** (if gh CLI available):
   ```bash
   gh release view v1.2.0 --json tagName 2>/dev/null
   ```

4. **Classification:**
   - ✅ **Safe to prune**: Tag exists AND GitHub release exists
   - ⚠️ **Warning**: Tag exists but no GitHub release (may be intentional)
   - ❌ **Protected**: No tag found - do NOT suggest for deletion

**Display release branch status:**
```markdown
### Release Branch Verification

| Branch | Tag | Release | Status |
|--------|-----|---------|--------|
| release/v1.2.0 | ✅ v1.2.0 | ✅ Released | Safe to prune |
| release/v1.3.0 | ✅ v1.3.0 | ❌ Missing | ⚠️ Warn before prune |
| release/v1.4.0 | ❌ Missing | ❌ Missing | 🛡️ Protected |
```

**Automatic protection**: Release branches without a corresponding tag are automatically excluded from the prune candidates and added to the protected list.

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

### Release Branches Protected (no tag/release)
- release/v1.4.0 - No tag found

### Errors (if any)
- [branch]: [error message]
```

## Safety Protocols

1. **Dry-run default** - Shows candidates without deleting unless `--execute` is used
2. **Protected branches** - main, master, develop, staging, production are never deleted
3. **Current branch** - Never deletes the branch you're currently on
4. **Merge verification** - Only deletes branches confirmed merged via `git branch --merged`
5. **Release branch verification** - Release branches require a corresponding tag before pruning; branches without tags are automatically protected
6. **Confirmation** - Asks for confirmation before deleting when using `--execute`
