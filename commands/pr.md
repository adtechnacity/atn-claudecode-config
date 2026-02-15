---
description: Pull Request Workflow
---

# Pull Request Workflow

## Integration

Related: **`/commit`** (pre-PR), **`/review-code`** (runs automatically in Step 2), **`/ship`** (full release flow), **`/fix-pr-comments`** (post-review)

Create a well-structured PR for the current branch.

**Note:** Optional - you can push directly with `git push` after `/commit`.

## Prerequisites

1. All changes committed
2. Tests pass locally
3. No merge conflicts with target branch

## Workflow

### 1. Gather Context
```bash
git branch --show-current
git status
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'
git log --oneline $(git merge-base HEAD origin/main)..HEAD
git diff origin/main...HEAD --stat
```

Verify there are commits ahead of the base branch. If not, stop — nothing to PR.

### 2. Code Review

Run `/review-code` (no arguments — it will review the branch diff automatically).

This performs a multi-agent review covering correctness, security, architecture, and impact analysis. It will:
- Surface findings with severity ratings
- Propose fixes for Critical/High issues
- Ask clarification questions if intent is ambiguous
- Apply fixes and re-validate if the user approves

### 3. Gate on Verdict

After `/review-code` completes, check the verdict:

| Verdict | Action |
|---------|--------|
| **APPROVE** | Proceed to PR creation |
| **APPROVE WITH SUGGESTIONS** | Proceed to PR creation (include suggestions in PR body) |
| **REQUEST CHANGES** | Fixes should have been applied in review. If user skipped fixes, warn and ask to confirm |
| **REJECT** | Do NOT create PR. Inform user of fundamental issues. Stop here |

If the user skipped fixes during review and verdict is REQUEST CHANGES:

**ASK USER** (use AskUserQuestion):
- Header: "PR gate"
- Question: "Review found unresolved issues (verdict: REQUEST CHANGES). Create PR anyway?"
- Options:
  - **Go back and fix** — Re-run `/review-code` to address issues
  - **Create as draft** — Create a draft PR noting unresolved issues
  - **Create anyway** — Create PR with unresolved issues documented

### 4. Analyze Changes

For each commit: type (feat/fix/refactor/docs/test/chore), affected components, breaking changes, related issues.

### 5. Generate PR Content

**Title:** Conventional commit format (`feat: Add auth`, `fix: Memory leak`)

**Body:**
```markdown
## Summary
<!-- 2-3 bullet points -->

## Changes
<!-- Key changes -->

## Review
<!-- Include verdict and risk score from /review-code -->
**Verdict**: [APPROVE | APPROVE WITH SUGGESTIONS] | **Risk**: [score]/100

<details>
<summary>Review details</summary>

<!-- Risk dashboard table from review report -->
<!-- Any remaining suggestions -->

</details>

## Testing
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Edge cases considered

## Breaking Changes
<!-- List or "None" -->

## Related Issues
<!-- Fixes #123 -->
```

### 6. Create PR
```bash
git push -u origin $(git branch --show-current)
gh pr create --title "TITLE" --body "BODY" --base main
```

If user chose "Create as draft" in Step 3, add `--draft` flag.

### 7. Post-Creation

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
