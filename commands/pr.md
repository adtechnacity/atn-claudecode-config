# Pull Request Workflow

Create a well-structured PR for the current branch.

**Note:** Optional - you can push directly with `git push` after `/commit`.

## Prerequisites

1. All changes committed
2. Branch pushed to remote
3. Tests pass locally
4. No merge conflicts with target branch

## Workflow

### 1. Gather Context
```bash
git branch --show-current
git status
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
git log --oneline $(git merge-base HEAD origin/main)..HEAD
git diff origin/main...HEAD --stat
```

### 2. Analyze Changes

For each commit: type (feat/fix/refactor/docs/test/chore), affected components, breaking changes, related issues.

### 3. Generate PR Content

**Title:** Conventional commit format (`feat: Add auth`, `fix: Memory leak`)

**Body:**
```markdown
## Summary
<!-- 2-3 bullet points -->

## Changes
<!-- Key changes -->

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Edge cases considered

## Breaking Changes
<!-- List or "None" -->

## Related Issues
<!-- Fixes #123 -->
```

### 4. Create PR
```bash
git push -u origin $(git branch --show-current)
gh pr create --title "TITLE" --body "BODY" --base main
```

### 5. Post-Creation

Return PR URL, suggest reviewers, mention CI checks.

## Options

- `--draft/-d`: Draft PR
- `--base <branch>`: Different base
- `--reviewer <user>`: Add reviewer
- `--label <label>`: Add labels

## Safety

- Never force push
- Verify branch is up to date
- Warn if >500 lines changed
