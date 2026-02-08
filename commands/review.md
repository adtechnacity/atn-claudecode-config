---
description: Code review for staged, branch, file, or PR changes
---

Review code for bugs, security, performance, and quality issues.

## Integration

Used by: **`/commit`** (Step 2), **`/audit-code`** (Phases 2-5)

Related: **`/cleanup`**, **`/performance`**, **`/commit`**

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

> "Review the following changes for bugs, security vulnerabilities, performance issues, and code quality. Only report issues with confidence >= 80."

### Review Checklist
- **Bugs**: Logic errors, null/undefined handling, race conditions, edge cases
- **Security**: Injection risks, auth gaps, input validation, secret exposure
- **Performance**: O(n^2)+ complexity, missing memoization, N+1 queries, memory leaks
- **Quality**: Naming, duplication, complexity, type safety, error handling

## Phase 3: TypeScript-Specific Review (if applicable)

Launch via Task tool (`subagent_type: "general-purpose"`) for TypeScript/React files:

> "Production readiness review: type safety, React patterns, Node.js best practices."

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
