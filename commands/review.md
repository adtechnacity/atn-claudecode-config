# Code Review Workflow

Review code changes for quality, correctness, security, and maintainability.

## Modes

Determine the review mode from user input:

### 1. PR Review: `/review pr [number]` or `/review pr [url]`
Review a GitHub pull request.

```bash
# Get PR details
gh pr view [number] --json title,body,files,additions,deletions,commits

# Get the diff
gh pr diff [number]

# Get comments and reviews
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

### 2. Branch Review: `/review branch [name]`
Review changes on a specific branch vs main.

```bash
# Get diff against main
git diff main...[branch] --stat
git diff main...[branch]
```

### 3. Staged Review: `/review staged` or `/review`
Review currently staged changes.

```bash
git diff --cached --stat
git diff --cached
```

### 4. File Review: `/review file [path]`
Review a specific file in its entirety.

Use the Read tool to read the file, then analyze it.

## Review Checklist

For each piece of code, check:

### Critical Issues (Must Fix)
- [ ] **Security vulnerabilities** - SQL injection, XSS, CSRF, auth bypass
- [ ] **Data integrity** - Race conditions, data corruption risks
- [ ] **Error handling** - Unhandled exceptions, missing error cases
- [ ] **Breaking changes** - API contract violations, backward incompatibility

### High Priority (Should Fix)
- [ ] **Type safety** - Missing types, any usage, unsafe casts
- [ ] **Performance** - N+1 queries, memory leaks, unnecessary re-renders
- [ ] **Logic errors** - Off-by-one, incorrect conditions, edge cases
- [ ] **Test coverage** - Missing tests for new functionality

### Medium Priority (Consider)
- [ ] **Code clarity** - Confusing naming, complex logic without comments
- [ ] **DRY violations** - Duplicated code that could be abstracted
- [ ] **Best practices** - Framework conventions, idioms

### Low Priority (Nitpicks)
- [ ] **Style** - Formatting inconsistencies (if not auto-formatted)
- [ ] **Documentation** - Missing JSDoc, outdated comments
- [ ] **Minor improvements** - Slightly cleaner alternatives

## Output Format

Structure your review as:

```markdown
## Code Review Summary

**Scope:** [What was reviewed]
**Risk Level:** [Low/Medium/High/Critical]

### Critical Issues
<!-- Must be fixed before merge -->

### Improvements
<!-- Recommended changes -->

### Suggestions
<!-- Optional enhancements -->

### Positive Notes
<!-- What was done well -->
```

## Tools to Use

1. **Explore agent** - Understand context and related code
2. **LSP** - Check references, definitions, types
3. **Grep** - Find related patterns across codebase
4. **typescript-code-reviewer agent** - For TypeScript-specific review

## Guidelines

- Be constructive, not critical
- Explain the "why" behind suggestions
- Provide code examples for fixes
- Acknowledge good patterns
- Prioritize issues by impact
- Don't nitpick on style if auto-formatters exist
