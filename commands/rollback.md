# Safe Rollback

Safely revert changes. Handles code rollbacks and tag management.

## Modes

### 1. Rollback Commit: `/rollback commit [hash]`

```bash
git show [hash] --stat           # Preview
git revert [hash] --no-edit      # Create revert commit
git revert [hash] --no-commit    # Or preview first
```

### 2. Rollback to Release: `/rollback release [tag]`

```bash
git tag -l --sort=-version:refname | head -10   # List tags
git diff [tag]..HEAD --stat                      # Preview changes
git checkout -b rollback/to-[tag]                # Create branch
git reset --hard [tag]
```

**Tag cleanup (ask user):** After rollback, offer to delete tags for broken releases:
```bash
git tag -d v$BAD_VERSION                    # Local (REQUIRES CONFIRMATION)
git push origin --delete v$BAD_VERSION      # Remote (REQUIRES CONFIRMATION)
```

**Re-shipping:** Use next patch version (v1.2.3 failed -> v1.2.4), or reuse if tag deleted.

### 3. Delete Tag: `/rollback tag [tag]`

Remove tag without code rollback (accidental tag, typo, wrong commit).

```bash
git show [tag] --stat
git tag -d [tag]                         # Local
git push origin --delete [tag]           # Remote (REQUIRES CONFIRMATION)
```

### 4. Rollback File: `/rollback file [path]`

```bash
git log --oneline -10 -- [path]      # File history
git checkout [commit] -- [path]      # Restore from commit
git checkout HEAD~1 -- [path]        # Or from previous
```

### 5. Rollback Last N: `/rollback last [n]`

```bash
git log --oneline -[n]           # Preview
git reset --soft HEAD~[n]        # Keep staged
git reset HEAD~[n]               # Keep unstaged
git reset --hard HEAD~[n]        # Discard (REQUIRES CONFIRMATION)
```

## Safety Protocol

**Before rollback:**
```bash
git branch backup/before-rollback-$(date +%Y%m%d-%H%M%S)
git status
```

**After rollback:**
1. Run tests
2. Check dependencies
3. Document reason

## Workflow

1. **Assess:** `git status`, `git log --oneline -10`, `git describe --tags --abbrev=0`
2. **Identify target:** Ask user what to rollback to, preserve or discard changes, production or dev
3. **Execute:** Run appropriate rollback mode
4. **Verify:** Run tests, check build
5. **Document:** Record rollback details

## Emergency Rollback (Production)

```bash
git branch backup/prod-$(date +%Y%m%d-%H%M%S)
git checkout [last-good-tag]
# git push --force origin [deploy-branch]  # REQUIRES CONFIRMATION
```

## Output Format

```markdown
## Rollback Summary

### Action Taken
- **Type:** [commit/release/file/tag revert]
- **Target:** [rollback target]
- **Backup:** [backup branch]

### Tags Affected
- **Deleted:** [list or "None"]
- **Current version:** [tag at HEAD]
- **Recommended next:** [version for re-ship]

### Verification
- Tests: [Pass/Fail]
- Build: [Pass/Fail]
- Issue resolved: [Yes/No]

### Next Steps
- [Follow-up actions]
```

## Options

- `--hard` - Discard all changes (requires confirmation)
- `--no-backup` - Skip backup (not recommended)
- `--dry-run` - Preview without changes
- `--delete-tags` - Delete tags newer than target
- `--keep-tags` - Skip tag cleanup prompt
