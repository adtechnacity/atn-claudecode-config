---
description: Audit test coverage and create missing tests
---

Audit test suite for coverage gaps and create high-value tests only.

## Integration

Used by: **`/ship`** (Phase 1), **`/commit`** (Step 2)
Related: **`/deps`**, **`/review`**

## Build System Detection

| Indicator | Test Command | Coverage |
|-----------|--------------|----------|
| `package.json` | `npm test` | `npm run test:coverage` |
| `mix.exs` | `mix test` | `mix test --cover` |
| `Cargo.toml` | `cargo test` | `cargo tarpaulin` |
| `pyproject.toml` | `pytest` | `pytest --cov` |

## Test Quality

**Before writing any test: "Does this test provide unique value?"**

### Useful Tests
- Test distinct code paths/behaviors
- Catch production bugs
- Document expected behavior
- Cover error-prone boundaries

### Redundant Tests
- Same code path with different data
- Trivial behavior (getters)
- Every enum value when one suffices

### Consolidation
- Multiple assertions for related behaviors
- Loops for exhaustive checks
- One representative per category

## Phases

### Phase 1: Audit Existing Tests

Launch via Task tool (`subagent_type: "general-purpose"`):
> "Review test files for redundancy with confidence scoring (0-100, report >= 80). Flag: duplicate code paths, trivial tests (getters, no-op assertions), repetitive validation. Count tests per file. Include file:line for each issue."

Consider consolidating/removing issues with >=80 confidence.

### Phase 2: Identify Coverage Gaps

Launch via Task tool (`subagent_type: "Explore"`):
> "Identify critical untested paths by tracing execution flows and mapping code coverage gaps. Prioritize: business logic, validation boundaries, error handling, edge cases. Skip: UI, delegating functions, framework wrappers. Note file:line for each gap."

Risk priority: **Critical** (business logic) > **High** (security) > **Medium** (error handling) > **Low** (obvious utilities)

### Phase 3: Create Tests

Consolidate related behaviors:
```
describe('functionName', () => {
  it('handles valid inputs correctly', () => { /* multiple assertions */ });
  it('rejects invalid inputs', () => { /* multiple assertions */ });
});
```

Test count guidelines: Validators 1-2, Business logic 3-5, Error handling 1-2, Utilities 1-2.

### Phase 4: Verification

Run test suite. Report: tests created, tests removed, remaining gaps, coverage metrics.

## Red Flags

- More tests than source lines
- Nearly identical test structures
- Tests that only verify "doesn't throw"
- Tests for private implementation details
