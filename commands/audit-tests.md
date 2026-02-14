---
description: Audit test coverage and create missing tests
---

Audit test suite for coverage gaps and create high-value tests only.

## Integration

Used by: **`/ship`** (via `/audit-all`)
Related: **`/audit-deps`**, **`/audit-code`**

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

## Mode Detection

Detect whether running standalone or inside `/audit-all`:

- **Standalone**: Run all 4 phases (audit, gaps, create tests, verify)
- **Inside `/audit-all`**: Run only Phases 1-2 (audit + gaps). Post findings via TaskCreate for the orchestrator. Skip Phases 3-4 (test creation and verification are handled by the orchestrator's quality gates).

Check if a task list already exists with `audit-all` tasks to determine mode.

## Phase 1 + Phase 2: Parallel Analysis

Launch both agents in a single message (`run_in_background: true`):

### Phase 1: Audit Existing Tests

Launch via Task tool (`subagent_type: "general-purpose"`, `run_in_background: true`):
> "Review test files for redundancy with confidence scoring (0-100, report >= 80). Flag: duplicate code paths, trivial tests (getters, no-op assertions), repetitive validation. Count tests per file. Include file:line for each issue.
>
> Post each finding as a task via TaskCreate:
>   subject: '[Test Audit] <brief description>'
>   description: Full details with file:line references
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 1, audit: 'tests', files: ['path']}"

### Phase 2: Identify Coverage Gaps

Launch via Task tool (`subagent_type: "Explore"`, `run_in_background: true`):
> "Identify critical untested paths by tracing execution flows and mapping code coverage gaps. Prioritize: business logic, validation boundaries, error handling, edge cases. Skip: UI, delegating functions, framework wrappers. Note file:line for each gap.
>
> Post each finding as a task via TaskCreate:
>   subject: '[Coverage Gap] <brief description>'
>   description: Full details with file:line references
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 2, audit: 'tests', files: ['path']}"

Risk priority: **Critical** (business logic) > **High** (security) > **Medium** (error handling) > **Low** (obvious utilities)

After both agents return, read all findings from TaskList.

## Phase 3: Create Tests (standalone only)

Skip this phase when running inside `/audit-all`.

Consolidate findings from Phases 1-2. For findings with >= 80 confidence:

**Cross-phase conflict resolution**: If Phase 1 flags a test as redundant but Phase 2 identifies the same path as needing coverage → refine the existing test to cover the gap instead of removing it.

Consolidate related behaviors:
```
describe('functionName', () => {
  it('handles valid inputs correctly', () => { /* multiple assertions */ });
  it('rejects invalid inputs', () => { /* multiple assertions */ });
});
```

Test count guidelines: Validators 1-2, Business logic 3-5, Error handling 1-2, Utilities 1-2.

## Phase 4: Verification (standalone only)

Skip this phase when running inside `/audit-all`.

Run test suite. Report: tests created, tests removed, remaining gaps, coverage metrics.

## Error Recovery

If an agent crashes mid-phase:
1. The other parallel agent's findings are still valid — continue with partial results
2. Note the gap in the summary (e.g., "Phase 1 audit incomplete — coverage gaps still identified")
3. Optionally re-dispatch the failed agent
4. Do not block on partial failure — partial results are valuable

## Red Flags

- More tests than source lines
- Nearly identical test structures
- Tests that only verify "doesn't throw"
- Tests for private implementation details
