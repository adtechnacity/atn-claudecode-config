# Debugging Assistant

Systematic debugging workflow to find and fix issues efficiently.

## Initial Context Gathering

Ask the user for (or extract from their message):
1. **Error message/behavior** - What's happening?
2. **Expected behavior** - What should happen?
3. **Reproduction steps** - How to trigger the bug?
4. **Recent changes** - What changed before this started?

## Debugging Workflow

### Step 1: Reproduce the Issue

First, understand and reproduce:

```bash
# Check recent commits that might have introduced the bug
git log --oneline -20

# See what files changed recently
git diff HEAD~5 --stat
```

### Step 2: Locate the Problem

Use the Explore agent to trace the execution path:

**For runtime errors:**
- Parse the stack trace
- Identify the failing file and line
- Trace back to the root cause

**For logic errors:**
- Identify the affected feature
- Map the data flow
- Find where actual diverges from expected

**For performance issues:**
- Profile the slow operation
- Identify bottlenecks
- Check for N+1 queries, memory leaks

### Step 3: Investigate Root Cause

Tools to use:

1. **Read** - Examine the failing code
2. **Grep** - Find related patterns
3. **LSP** - Check definitions, references, types
4. **Bash** - Run the code with debug output

**Add strategic logging:**
```typescript
// Temporary debug logging
console.log('[DEBUG] functionName:', { param1, param2, result });
```

### Step 4: Identify Candidates

List possible causes ranked by likelihood:

```markdown
## Root Cause Analysis

### Most Likely (80%+)
1. [Cause] - [Evidence]

### Possible (50-80%)
2. [Cause] - [Evidence]

### Less Likely (<50%)
3. [Cause] - [Evidence]
```

### Step 5: Verify Hypothesis

For each candidate:
1. Write a test that would fail with the bug
2. Or add logging to confirm the theory
3. Run and observe

### Step 6: Implement Fix

Once root cause is confirmed:
1. **Propose the fix** to the user
2. **Get approval** before implementing
3. **Make minimal change** to fix the issue
4. **Remove debug code** after fixing

### Step 7: Add Regression Test

Create a test that:
- Would have caught this bug
- Prevents future regressions
- Documents the expected behavior

```typescript
it('should handle [edge case] correctly', () => {
  // Arrange
  const input = /* the problematic input */;

  // Act
  const result = functionUnderTest(input);

  // Assert
  expect(result).toBe(/* expected output */);
});
```

### Step 8: Verify Fix

```bash
# Run tests
npm test

# Run the specific reproduction case
# Verify the error no longer occurs
```

## Common Debugging Patterns

### Async/Promise Issues
- Check for missing `await`
- Look for race conditions
- Verify error handling in promises

### State Management Issues
- Check for stale closures
- Verify state update timing
- Look for mutation of immutable state

### Type Errors
- Check for `null`/`undefined` access
- Verify type assertions
- Look for incorrect type guards

### API/Network Issues
- Check request/response format
- Verify authentication
- Look for CORS issues

## Output Format

```markdown
## Debug Report

### Issue
[Description of the bug]

### Root Cause
[Explanation of why it happened]

### Fix
[Description of the fix]

### Files Changed
- [file1]: [change description]
- [file2]: [change description]

### Testing
- [x] Bug no longer reproduces
- [x] Regression test added
- [x] All tests pass

### Prevention
[How to prevent similar issues in the future]
```
