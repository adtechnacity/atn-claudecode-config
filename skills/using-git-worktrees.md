---
name: using-git-worktrees
description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans
---

# Using Git Worktrees

Create isolated workspaces sharing the same repository for parallel branch work.

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

## Directory Selection Priority

1. **Check existing:** `.worktrees/` (preferred) or `worktrees/`
2. **Check CLAUDE.md:** Look for worktree directory preference
3. **Ask user:** Offer `.worktrees/` (project-local, hidden) or `~/.config/worktrees/<project>/` (global)

## Safety Verification

For project-local directories, **verify the directory is gitignored before creating:**

```bash
git check-ignore -q .worktrees 2>/dev/null
```

**If NOT ignored:** Add to `.gitignore` and commit before proceeding. This prevents worktree contents from being tracked.

Global directories (`~/.config/...`) need no verification.

## Creation Steps

### 1. Detect Project

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. Create Worktree

```bash
git worktree add "$WORKTREE_DIR/$BRANCH_NAME" -b "$BRANCH_NAME"
cd "$WORKTREE_DIR/$BRANCH_NAME"
```

### 3. Run Project Setup

Auto-detect from project files:

| File | Command |
|------|---------|
| `package.json` | `npm install` |
| `mix.exs` | `mix deps.get` |
| `Cargo.toml` | `cargo build` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.mod` | `go mod download` |

### 4. Verify Clean Baseline

Run tests. If they fail, report failures and ask whether to proceed.

### 5. Report

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Quick Reference

| Situation | Action |
|-----------|--------|
| `.worktrees/` exists | Use it (verify ignored) |
| `worktrees/` exists | Use it (verify ignored) |
| Both exist | Use `.worktrees/` |
| Neither exists | Check CLAUDE.md -> Ask user |
| Directory not ignored | Add to .gitignore + commit |
| Tests fail during baseline | Report failures + ask |

## Red Flags

- Creating worktree without verifying it's ignored (project-local)
- Skipping baseline test verification
- Assuming directory location when ambiguous
- Hardcoding setup commands instead of auto-detecting

## Integration

**Called by:** `subagent-driven-development`, `executing-plans`

**Pairs with:** `finishing-a-development-branch` (cleanup after work complete)
