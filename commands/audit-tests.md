---
description: Audit test coverage and create missing tests
---

Audit the test suite for coverage gaps and create only high-value tests.

## Build System Detection

Detect the project's build system and run appropriate test commands:

| Indicator | Build System | Test Command |
|-----------|--------------|--------------|
| `package.json` | npm/Node.js | `npm test` |
| `mix.exs` | Elixir/Mix | `mix test` |
| `Cargo.toml` | Rust/Cargo | `cargo test` |
| `pyproject.toml` | Python | `pytest` |

## Test Quality Principles

**Before writing any test, ask: "Does this test provide unique value?"**

### What Makes a Useful Test
- Tests a distinct code path or behavior
- Catches bugs that would otherwise reach production
- Documents expected behavior for future developers
- Tests boundary conditions that are easy to get wrong

### What Makes a Redundant Test
- Tests the same code path as another test with different data
- Tests trivial/obvious behavior (e.g., getter returns value)
- Tests multiple status codes that share identical handling logic
- Tests each enum value when one representative test suffices

### Consolidation Techniques
- Use **one test with multiple assertions** for related behaviors
- Use **loops** for exhaustive checks (e.g., all valid input types)
- Test **one representative** from each category, not every variant

## Agent Integration

| Agent | Phase | Purpose |
|-------|-------|---------|
| `code-reviewer` | Audit Existing Tests | Identify redundant or low-quality tests |
| `code-explorer` | Identify Critical Paths | Find untested business logic and hot paths |

Spawn via Task tool with `subagent_type` set to `feature-dev:code-reviewer` or `feature-dev:code-explorer`.

## Phase 1: Audit Existing Tests

### 1.1 Spawn Code Reviewer (Test Quality Focus)
Launch `feature-dev:code-reviewer` with prompt:
> "Review the test files for redundancy and quality issues. Flag: tests that exercise the same code path, tests for trivial behavior, repetitive validation tests, tests that don't assert meaningful behavior. Count tests per file."

### 1.2 Review Agent Findings
For issues with ≥80 confidence, consider consolidating or removing redundant tests.

## Phase 2: Identify Coverage Gaps

### 2.1 Spawn Code Explorer (Critical Paths Focus)
Launch `feature-dev:code-explorer` with prompt:
> "Identify critical untested code paths. Prioritize: (1) Business logic and core algorithms, (2) Validation boundaries, (3) Error handling branches, (4) Edge cases in algorithms. Skip: UI code, simple delegating functions, framework wrappers."

### 2.2 Prioritize Gaps by Risk
- **Critical**: Business logic - bugs break the product
- **High**: Validation/security boundaries - bugs create vulnerabilities
- **Medium**: Error handling - bugs cause poor UX
- **Low**: Utilities with obvious implementations

## Phase 3: Create Tests

### 3.1 Test Structure
Consolidate related behaviors:
```
describe('functionName', () => {
  it('handles valid inputs correctly', () => {
    // Multiple assertions for related valid cases
  });

  it('rejects invalid inputs', () => {
    // Multiple assertions for related invalid cases
  });
});
```

### 3.2 Anti-Patterns to Avoid
```
// BAD: Separate tests for each invalid input
it('rejects empty string', () => { ... });
it('rejects null', () => { ... });
it('rejects undefined', () => { ... });

// GOOD: One test covering the validation
it('rejects non-string and empty values', () => {
  // All invalid cases in one test
});
```

### 3.3 Test Count Guidelines
- **Validators**: 1-2 tests per function
- **Business logic**: 3-5 tests per function
- **Error handling**: 1-2 tests per error type
- **Utilities**: 1-2 tests unless complex

## Phase 4: Verification

Run the project's test suite and ensure all tests pass.

### Summary Report
- Tests created (should be minimal, focused)
- Tests removed/consolidated
- Remaining gaps with justification

## Red Flags

- Test file has more tests than source file has lines
- Multiple tests with nearly identical structure
- Tests that only verify "it doesn't throw"
- Tests for private/internal implementation details
