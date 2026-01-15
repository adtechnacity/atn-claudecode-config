# Safe Rollback

Safely revert changes when something goes wrong.

## Modes

### 1. Rollback Commit: `/rollback commit [hash]`

Revert a specific commit.

```bash
# Show the commit to be reverted
git show [hash] --stat

# Create revert commit
git revert [hash] --no-edit

# Or revert without committing (to review first)
git revert [hash] --no-commit
```

### 2. Rollback to Release: `/rollback release [tag]`

Roll back to a previous release version.

```bash
# List recent tags
git tag -l --sort=-version:refname | head -10

# Show what would change
git diff [tag]..HEAD --stat

# Create rollback branch
git checkout -b rollback/to-[tag]
git reset --hard [tag]
```

### 3. Rollback File: `/rollback file [path]`

Restore a specific file to its previous state.

```bash
# Show file history
git log --oneline -10 -- [path]

# Restore from specific commit
git checkout [commit] -- [path]

# Or restore from HEAD~1
git checkout HEAD~1 -- [path]
```

### 4. Rollback Last N Commits: `/rollback last [n]`

Undo the last N commits.

```bash
# Show what will be undone
git log --oneline -[n]

# Soft reset (keep changes staged)
git reset --soft HEAD~[n]

# Or mixed reset (keep changes unstaged)
git reset HEAD~[n]

# Or hard reset (discard changes) - requires confirmation
git reset --hard HEAD~[n]
```

## Safety Protocol

**Before any rollback:**
1. Create a backup branch
2. Verify current state is clean
3. Understand what will be affected

```bash
# Always create backup first
git branch backup/before-rollback-$(date +%Y%m%d-%H%M%S)

# Check for uncommitted changes
git status
```

**After rollback:**
1. Run tests to verify stability
2. Check for broken dependencies
3. Document the reason for rollback

## Rollback Workflow

### Step 1: Assess the Situation

```bash
# Current state
git status
git log --oneline -10

# What's deployed (if applicable)
git describe --tags --abbrev=0
```

### Step 2: Identify Rollback Target

Ask the user:
- What commit/release to roll back to?
- Should changes be preserved or discarded?
- Is this production or development?

### Step 3: Execute Rollback

Based on the mode, execute the appropriate rollback.

### Step 4: Verify

```bash
# Run tests
npm test

# Check build
npm run build

# Verify the issue is resolved
```

### Step 5: Document

Create a record of the rollback:

```markdown
## Rollback Record

**Date:** [timestamp]
**Reason:** [why rollback was needed]
**From:** [commit/tag rolled back from]
**To:** [commit/tag rolled back to]
**Verification:** [how we verified the rollback worked]
**Follow-up:** [what needs to happen next]
```

## Emergency Rollback (Production)

For production issues:

```bash
# 1. Create backup
git branch backup/prod-$(date +%Y%m%d-%H%M%S)

# 2. Checkout last known good
git checkout [last-good-tag]

# 3. Force push to deploy branch (REQUIRES CONFIRMATION)
# git push --force origin [deploy-branch]

# 4. Deploy (platform specific)
```

**WARNING:** Force pushes require explicit user confirmation.

## Output Format

```markdown
## Rollback Summary

### Action Taken
- **Type:** [commit/release/file revert]
- **Target:** [what was rolled back to]
- **Backup:** [backup branch name]

### Changes Reverted
- [List of changes undone]

### Verification
- Tests: [Pass/Fail]
- Build: [Pass/Fail]
- Issue resolved: [Yes/No]

### Next Steps
- [Required follow-up actions]
```

## Options

- `--hard` - Discard all changes (requires confirmation)
- `--no-backup` - Skip backup branch creation (not recommended)
- `--dry-run` - Show what would happen without making changes
