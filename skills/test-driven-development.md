---
name: test-driven-development
description: Enforce test-driven development workflow (Red-Green-Refactor). Use when building new features, fixing bugs, or when the user asks to follow TDD practices.
---

# Test-Driven Development

Write the test first. Watch it fail. Write minimal code to pass.

**Core principle:** If you didn't watch the test fail, you don't know if it tests the right thing.

## When to Use

- New features, bug fixes, behavior changes, refactoring
- **Exceptions** (ask user): throwaway prototypes, generated code, config files

## Red-Green-Refactor

### RED — Write Failing Test

One minimal test showing what should happen. One behavior, clear name, real code (no mocks unless unavoidable).

**Run it. Watch it fail.** This is mandatory.

Confirm:
- Test **fails** (not errors from typos/imports)
- Failure message matches expectations
- Fails because the feature is missing

Test passes immediately? You're testing existing behavior — fix the test.

### GREEN — Minimal Code

Write the **simplest** code to make the test pass. Don't add features, refactor, or "improve" beyond what the test requires.

**Run it. Watch it pass.** Also mandatory.

Confirm:
- Test passes
- Other tests still pass
- No errors or warnings in output

Test fails? Fix the code, not the test.

### REFACTOR — Clean Up (only after green)

Remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

### Repeat

Next failing test for the next behavior.

## Bug Fix Workflow

Bug found → write failing test that reproduces it → follow Red-Green-Refactor → test proves fix and prevents regression.

Never fix bugs without a test.

## Good Tests

| Quality | Right | Wrong |
|---------|-------|-------|
| Minimal | Tests one thing | "and" in name = split it |
| Clear | Name describes behavior | `test('test1')` |
| Intent | Demonstrates desired API | Tests implementation details |
| Real | Uses real code paths | Mocks everything |

## Red Flags — Start Over

If you catch yourself:
- Writing production code before the test
- Test passes immediately (never saw it fail)
- Adding tests "after" to verify existing code
- Rationalizing "just this once" or "too simple to test"
- Keeping pre-written code "as reference"

**Delete the code. Write the test first. Implement fresh.**

## When Stuck

| Problem | Solution |
|---------|----------|
| Don't know how to test | Write the wished-for API first. Write assertion first. |
| Test too complicated | Design too complicated — simplify the interface |
| Must mock everything | Code too coupled — use dependency injection |
| Test setup huge | Extract helpers. Still complex? Simplify design. |

## Verification Checklist

Before marking work complete:
- [ ] Every new function/method has a test
- [ ] Watched each test fail before implementing
- [ ] Each failure was for the expected reason (missing feature, not typo)
- [ ] Wrote minimal code to pass each test
- [ ] All tests pass with clean output
- [ ] Edge cases and error paths covered
