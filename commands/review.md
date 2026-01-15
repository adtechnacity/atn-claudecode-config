# Code Review Workflow

Review code changes for quality, correctness, security, and maintainability.

## Modes

### 1. PR Review: `/review pr [number|url]`
```bash
gh pr view [number] --json title,body,files,additions,deletions,commits
gh pr diff [number]
gh api repos/{owner}/{repo}/pulls/{number}/comments
```

### 2. Branch Review: `/review branch [name]`
```bash
git diff main...[branch] --stat
git diff main...[branch]
```

### 3. Staged Review: `/review staged` or `/review`
```bash
git diff --cached --stat
git diff --cached
```

### 4. File Review: `/review file [path]`
Read and analyze the entire file.

### 5. Release Review: `/review release [tag]` or `/review release [from]..[to]`
```bash
git tag -l --sort=-version:refname | head -10
PREV_TAG=$(git tag -l --sort=-version:refname | grep -A1 "^[tag]$" | tail -1)
git diff $PREV_TAG..[tag] --stat
git log --oneline [from]..[to]
```

## Review Checklist

### Critical (Must Fix)
- Security vulnerabilities (SQL injection, XSS, CSRF, auth bypass)
- Data integrity (race conditions, corruption risks)
- Error handling (unhandled exceptions, missing cases)
- Breaking changes (API violations, backward incompatibility)

### High (Should Fix)
- Type safety (missing types, any usage, unsafe casts)
- Performance (N+1 queries, memory leaks, unnecessary re-renders)
- Logic errors (off-by-one, incorrect conditions, edge cases)
- Test coverage for new functionality

### Medium (Consider)
- Code clarity (naming, complexity)
- DRY violations
- Framework best practices

### Low (Nitpicks)
- Style (if not auto-formatted)
- Documentation gaps
- Minor improvements

## Output Format

```markdown
## Code Review Summary

**Scope:** [What was reviewed]
**Risk Level:** [Low/Medium/High/Critical]

### Critical Issues
### Improvements
### Suggestions
### Positive Notes
```

## Tools

- **Explore agent** - Context and related code
- **LSP** - References, definitions, types
- **Grep** - Pattern search
- **typescript-code-reviewer agent** - TypeScript-specific review

## Guidelines

- Be constructive
- Explain the "why"
- Provide code examples
- Acknowledge good patterns
- Prioritize by impact
- Skip style nitpicks if auto-formatters exist
