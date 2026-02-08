---
description: Fix automated PR review comments (CodeRabbit, CodeScene, etc.)
argument-hint: Optional PR number or URL
---

## Integration

Related: **`/pr`** (creates PRs), **`/audit-code`** (proactive code quality), **`/commit`** (commit fixes)

## Phase 1: Identify the PR

### 1.1 Resolve PR

If a PR number or URL is provided, use that. Otherwise, detect from current branch:

```bash
gh pr view --json number,title,headRefName,url
```

If no PR exists for the current branch, stop and inform the user.

### 1.2 Fetch All Comments

Retrieve both review comments (inline) and issue comments (top-level):

```bash
gh pr view <number> --json comments,reviews,reviewRequests
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate
gh api repos/{owner}/{repo}/issues/<number>/comments --paginate
```

---

## Phase 2: Filter Automated Comments

### 2.1 Identify Bot Comments

Filter comments by known automated review tool authors and patterns:

| Tool | Author Pattern | Comment Markers |
|------|---------------|-----------------|
| **CodeRabbit** | `coderabbitai[bot]`, `coderabbit` | `<!-- coderabbit -->`, summary blocks |
| **CodeScene** | `codescene[bot]`, `codescene` | CodeScene badges, health indicators |
| **SonarCloud** | `sonarcloud[bot]` | Quality gate status |
| **Codacy** | `codacy[bot]` | Codacy badges |
| **DeepSource** | `deepsource[bot]` | DeepSource issue links |
| **Snyk** | `snyk[bot]` | Security vulnerability notices |
| **Dependabot** | `dependabot[bot]` | Dependency update notices |
| **GitHub Actions** | `github-actions[bot]` | CI/lint results |

Also match any comment author ending in `[bot]` that contains code suggestions or file references.

### 2.2 Extract Actionable Items

For each bot comment, extract:
- **File path** and line number (from inline comments or code blocks)
- **Severity** (critical, warning, suggestion, nitpick)
- **Category** (security, bug, performance, style, maintainability)
- **Description** of the issue
- **Suggested fix** (if provided, especially CodeRabbit's diff suggestions)

Ignore:
- Summary/overview comments (PR description summaries, walkthrough tables)
- Resolved/outdated comments
- Comments already addressed by subsequent commits
- Pure informational comments with no actionable feedback

---

## Phase 3: Categorize and Prioritize

### 3.1 Present Overview

```markdown
## PR Review Comments: #<number>

**Source**: [tool names detected]
**Total comments**: X actionable, Y informational (skipped)

### By Priority
| # | Tool | File | Line | Category | Severity | Summary |
|---|------|------|------|----------|----------|---------|
```

### 3.2 Classify Issues

| Priority | Criteria | Action |
|----------|----------|--------|
| **Must fix** | Security vulnerabilities, bugs, data loss risks | Fix immediately |
| **Should fix** | Performance issues, error handling gaps, type safety | Fix unless justified |
| **Consider** | Style, naming, minor improvements | Fix if quick, skip if subjective |
| **Skip** | False positives, subjective preferences, already handled | Dismiss with reason |

**ASK USER**: Present the categorized list and get approval before fixing. User may reclassify items.

---

## Phase 4: Investigate and Fix

For each approved issue (highest priority first):

### 4.1 Understand Context

Read the referenced file and surrounding code. Understand why the tool flagged it.

### 4.2 Validate the Issue

Before fixing, confirm the issue is real:
- Is the tool's analysis correct given the full context?
- Does the suggested fix introduce new problems?
- Is there a project-specific reason for the current code?

If the issue is a **false positive**, note it for Phase 5.

### 4.3 Apply Fix

- If the tool provides a concrete diff suggestion (e.g., CodeRabbit's `suggestion` blocks), evaluate and apply if correct
- If only a description is given, implement the minimal fix
- Follow existing code patterns and project conventions
- Run type checker and linter after each fix to catch regressions

### 4.4 Batch Related Fixes

Group fixes by file to minimize context switching. Apply all fixes to a file before moving to the next.

---

## Phase 5: Respond to False Positives

For issues identified as false positives or intentionally skipped:

Suggest that the user reply to the bot comment explaining why (do NOT post comments automatically):

```markdown
### Suggested Responses (for you to post if desired)

**Comment #X** (CodeRabbit - [file]:[line]):
> This is intentional because [reason]. The [pattern/approach] is used here for [justification].

**Comment #Y** (CodeScene - [file]:[line]):
> False positive. The complexity is warranted here because [reason].
```

---

## Phase 6: Validation

### 6.1 Run Checks

Run type checker, linter, and tests to verify fixes don't break anything.

### 6.2 Review Changes

```bash
git diff
```

Ensure all changes are intentional and minimal.

---

## Phase 7: Report

```markdown
## PR Comment Fix Report: #<number>

**Tools detected**: [list]
**Comments processed**: X of Y

### Fixed
| # | Tool | File:Line | Issue | Fix Applied |
|---|------|-----------|-------|-------------|

### Skipped (False Positive / Intentional)
| # | Tool | File:Line | Issue | Reason |
|---|------|-----------|-------|--------|

### Deferred
| # | Tool | File:Line | Issue | Reason |
|---|------|-----------|-------|--------|

**Validation**: typecheck [pass/fail], lint [pass/fail], tests [pass/fail]
```

**ASK USER**: "Ready to commit these fixes? I'll use `/commit` to validate and commit."

## Options

- `/fix-pr-comments` - Fix comments on current branch's PR
- `/fix-pr-comments 123` - Fix comments on PR #123
- `/fix-pr-comments https://github.com/org/repo/pull/123` - Fix comments by URL
