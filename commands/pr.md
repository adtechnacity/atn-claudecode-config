# Pull Request Workflow

Create a well-structured pull request for the current branch with comprehensive description and proper validation.

**Note:** This command is optional. You can also push directly with `git push` after `/commit`.

## Prerequisites Check

Before creating the PR, verify:
1. All changes are committed (no uncommitted changes)
2. Branch is pushed to remote
3. Tests pass locally
4. No merge conflicts with target branch

## Workflow

### Step 1: Gather Context

Run these commands to understand the changes:

```bash
# Get current branch and remote status
git branch --show-current
git status

# Get base branch (usually main or master)
git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'

# View all commits on this branch since diverging
git log --oneline $(git merge-base HEAD origin/main)..HEAD

# Get the full diff for PR description
git diff origin/main...HEAD --stat
```

### Step 2: Analyze Changes

For each commit, understand:
- What type of change (feat, fix, refactor, docs, test, chore)
- What components/files were affected
- Breaking changes if any
- Related issues or tickets

### Step 3: Generate PR Content

Create a PR with this structure:

**Title:** Follow conventional commit format
- `feat: Add user authentication`
- `fix: Resolve memory leak in dashboard`
- `refactor: Simplify API error handling`

**Body Template:**
```markdown
## Summary
<!-- 2-3 bullet points describing what this PR does -->

## Changes
<!-- List of key changes made -->

## Testing
<!-- How to test these changes -->
- [ ] Unit tests pass
- [ ] Manual testing completed
- [ ] Edge cases considered

## Screenshots
<!-- If UI changes, add before/after screenshots -->

## Breaking Changes
<!-- List any breaking changes, or "None" -->

## Related Issues
<!-- Link to related issues: Fixes #123, Relates to #456 -->
```

### Step 4: Create the PR

```bash
# Push branch if needed
git push -u origin $(git branch --show-current)

# Create PR using GitHub CLI
gh pr create \
  --title "PR_TITLE" \
  --body "PR_BODY" \
  --base main
```

### Step 5: Post-Creation

After PR is created:
1. Return the PR URL to the user
2. Suggest adding reviewers if appropriate
3. Mention any CI checks to watch

## Options

If the user provides arguments:
- `--draft` or `-d`: Create as draft PR
- `--base <branch>`: Use different base branch
- `--reviewer <user>`: Add specific reviewer
- `--label <label>`: Add labels

## Safety

- Never force push during PR creation
- Always verify branch is up to date with base
- Warn if PR is large (>500 lines changed)
