# Finishing a Development Branch

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests -> Present options -> Execute choice -> Clean up.

## The Process

### Step 1: Verify Tests

Run the project's test suite. **If tests fail, stop.** Do not proceed until tests pass.

### Step 2: Determine Base Branch

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Confirm with user if uncertain.

### Step 3: Present Options

Present exactly these 4 options:

1. **Merge locally** — Merge back to base branch
2. **Push and create PR** — Push branch and create pull request
3. **Keep as-is** — Leave branch for later
4. **Discard** — Delete branch and all work

### Step 4: Execute Choice

**Option 1 — Merge locally:**
```bash
git checkout <base-branch>
git pull
git merge <feature-branch>
# Verify tests on merged result
git branch -d <feature-branch>
```

**Option 2 — Push and create PR:**
```bash
git push -u origin <feature-branch>
gh pr create --title "<title>" --body "<summary>"
```

**Option 3 — Keep as-is:**
Report branch name and worktree path. Don't clean up.

**Option 4 — Discard:**
Require typed "discard" confirmation first. Then:
```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

### Step 5: Cleanup Worktree

For Options 1, 2, 4 — remove worktree if applicable:
```bash
git worktree remove <worktree-path>
```

For Option 3 — keep worktree.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | Y | - | - | Y |
| 2. Create PR | - | Y | Y | - |
| 3. Keep as-is | - | - | Y | - |
| 4. Discard | - | - | - | Y (force) |

## Red Flags

- Proceeding with failing tests
- Merging without verifying tests on result
- Deleting work without confirmation
- Force-pushing without explicit request
- Open-ended "what should I do?" instead of structured 4 options

## Integration

**Called by:** `workflows/subagent-dev.md`, `workflows/execute.md`
