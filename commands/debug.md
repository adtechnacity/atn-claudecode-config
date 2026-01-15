# Debugging Assistant

Systematic debugging workflow to find and fix issues.

## Initial Context

Gather from the user:
1. **Error/behavior** - What's happening?
2. **Expected behavior** - What should happen?
3. **Reproduction steps** - How to trigger it?
4. **Recent changes** - What changed?

## Workflow

### 1. Reproduce
```bash
git log --oneline -20
git diff HEAD~5 --stat
```

### 2. Locate

**Runtime errors:** Parse stack trace, identify failing line, trace to root cause.

**Logic errors:** Map data flow, find where actual diverges from expected.

**Performance:** Profile operation, identify bottlenecks (N+1 queries, memory leaks).

### 3. Investigate

Use **Read**, **Grep**, **LSP**, **Bash** to examine code and run with debug output.

### 4. Identify Candidates

Rank by likelihood:
- **Most Likely (80%+)**: [Cause] - [Evidence]
- **Possible (50-80%)**: [Cause] - [Evidence]
- **Less Likely (<50%)**: [Cause] - [Evidence]

### 5. Verify Hypothesis

For each candidate: write a failing test or add logging to confirm.

### 6. Implement Fix

1. Propose fix to user
2. Get approval before implementing
3. Make minimal change
4. Remove debug code

### 7. Add Regression Test

Create a test that would have caught this bug and prevents future regressions.

### 8. Verify Fix
```bash
npm test
# Run reproduction case - verify error gone
```

## Common Patterns

| Category | Check For |
|----------|-----------|
| Async | Missing `await`, race conditions, unhandled promise errors |
| State | Stale closures, timing issues, mutation of immutable state |
| Types | null/undefined access, incorrect type guards |
| API | Request/response format, auth, CORS |

## Output

```markdown
## Debug Report

### Issue
[Description]

### Root Cause
[Why it happened]

### Fix
[What was changed]

### Files Changed
- [file]: [change]

### Testing
- [x] Bug no longer reproduces
- [x] Regression test added
- [x] All tests pass

### Prevention
[How to prevent similar issues]
```
