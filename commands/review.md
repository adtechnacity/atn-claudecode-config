---
description: Code review for staged, branch, file, or PR changes
---

Review code for bugs, security, performance, and quality issues.

## Integration

Standalone command. Related: **`/cleanup`**, **`/performance`**, **`/commit`**, **`/audit-code`**

Hook: **`security-reminder.py`** catches insecure patterns on edits

## Modes

- `/review` - Review unstaged changes (`git diff`)
- `/review staged` - Review staged changes (`git diff --cached`)
- `/review file <path>` - Review a specific file
- `/review branch` - Review all changes on current branch vs main
- `/review pr <number>` - Review a pull request

## Phase 1: Gather Changes

```bash
# Default: unstaged changes
git diff

# Staged
git diff --cached

# Branch diff vs main
git diff main...HEAD

# PR
gh pr diff <number>
```

## Phase 2: Code Review

Launch via Task tool (`subagent_type: "general-purpose"`):

> "You are an expert code reviewer. Review the following changes for bugs, security vulnerabilities, performance issues, and code quality. Rate each issue on a confidence scale of 0-100. Only report issues with confidence >= 80. For each issue, provide: confidence score, file:line, clear description, specific fix suggestion. Group by severity (Critical vs Important). Verify adherence to project conventions in CLAUDE.md."

### Review Checklist
- **Bugs**: Logic errors, null/undefined handling, race conditions, edge cases
- **Security**: Injection risks, auth gaps, input validation, secret exposure
- **Performance**: O(n^2)+ complexity, missing memoization, N+1 queries, memory leaks
- **Quality**: Naming, duplication, complexity, type safety, error handling

## Phase 3: TypeScript-Specific Review (if applicable)

Launch via Task tool (`subagent_type: "general-purpose"`) for TypeScript/React files:

> "You are a senior TypeScript/React/Node.js engineer. Production readiness review covering: type safety (no `any`, proper generics, discriminated unions), React patterns (re-render risks, hook deps, error boundaries, a11y), Node.js (async error handling, input validation, no floating promises), and production concerns (graceful degradation, structured logging, bundle size). Rate confidence 0-100, only report >= 80."

## Phase 4: Report

```markdown
## Code Review

**Risk Level:** Low/Medium/High/Critical
**Production Ready:** Yes/No/With Changes

### Critical Issues (Must Fix)
| Issue | Location | Impact | Fix |

### Improvements (Should Fix)
| Issue | Location | Effort | Benefit |

### Suggestions
- [Suggestion with rationale]

### Summary
**Priority Actions:** 1. ... 2. ... 3. ...
**Next Steps:** Fix issues -> /commit -> git push
```

## Guidelines

- Only report issues with confidence >= 80
- Be actionable: include file:line and specific fix
- Distinguish bugs from style preferences
- Consider project conventions (CLAUDE.md)
- Balance thoroughness with pragmatism
