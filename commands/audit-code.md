---
description: Audit codebase for performance, security, and maintainability issues
---

Comprehensive code audit focused on improving existing code, not adding features.

## Integration

Used by: **`/ship`** (Phase 1), **`/commit`** (manual)

Related: **`/cleanup`**, **`/performance`**, **`/deps`**, **`/review`**

## Build System Detection

| Indicator | Type Check | Lint | Test | Build |
|-----------|------------|------|------|-------|
| `package.json` | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | `mypy .` | `ruff check .` | `pytest` | N/A |

Skip unavailable commands.

Spawn agents via Task tool with `subagent_type: "Explore"` for investigation or `"general-purpose"` for review/fixes.

## Phase 1: Static Analysis

### 1.1 Run Automated Checks
Run type checker, linter, and tests. Document failures/warnings.

### 1.2 Check Dependencies
- npm: `npm outdated && npm audit`
- mix: `mix hex.outdated && mix deps.audit`
- cargo: `cargo outdated && cargo audit`
- pip: `pip list --outdated && pip-audit`

Flag major updates, security advisories, unused dependencies.

## Phase 2: Security Audit

### 2.1 Security Scanner Agent (`subagent_type: "general-purpose"`)
> "Perform security audit: OWASP Top 10, secret detection, dependency CVEs. Rate each finding with confidence 0-100, only report >= 80. Include file:line and specific remediation."

### 2.2 Code Reviewer - Security (`subagent_type: "general-purpose"`)
> "Review for XSS, injection, insecure data handling, permission issues. Focus on auth code, API handlers, user input. Rate confidence 0-100, only report >= 80."

### 2.3 Manual Checks
Credential storage, config permissions, API key exposure, input validation.

### 2.4 Merge Findings
Combine agent issues (>=80 confidence) with manual findings. Classify by severity.

## Phase 3: Performance Audit

### 3.1 Performance Analyzer (`subagent_type: "Explore"`)
> "Analyze bottlenecks, Core Web Vitals, bundle sizes, render performance. Include file:line references."

Or run `/performance` command.

### 3.2 Code Explorer - Hot Paths (`subagent_type: "Explore"`)
> "Trace hot paths: performance-critical sections, frequently called functions, data pipelines, execution flows. Follow call chains and note data transformations at each step."

### 3.3 Analyze Hot Paths
Check for: O(n^2)+ algorithms, missing early returns, repeated computations, large non-streaming operations.

### 3.4 Memory and Async
Check for: large data held unnecessarily, uncleaned listeners/subscriptions, sequential awaits (parallelize), missing async error handling.

### 3.5 Build Output
Run production build, check bundle sizes and unused code.

## Phase 4: Maintainability Audit

### 4.1 Code Reviewer - Quality (`subagent_type: "general-purpose"`)
> "Review for duplication, complexity, type safety, project conventions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix."

### 4.2 Manual Checks
Functions >50 lines or >3 nesting levels, unused exports/dead code, unjustified weak typing, magic numbers.

### 4.3 Merge Findings
Use `/cleanup` for dead code removal.

## Phase 5: Reliability Audit

### 5.1 Code Reviewer - Reliability (`subagent_type: "general-purpose"`)
> "Review for error handling gaps, null handling, edge cases, race conditions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix."

### 5.2 Manual Checks
External API error handling, resource cleanup, graceful degradation, retry logic/timeouts.

## Phase 6: Fixes and Reporting

### 6.1 Categorize Issues
- **Critical**: Security/data loss - fix immediately
- **High**: Performance/reliability bug - fix soon
- **Medium**: Maintainability/minor bug - fix when convenient
- **Low**: Style/minor improvement - backlog

### 6.2 Apply Fixes
For Critical/High: create fix, verify no regressions, run checks.

### 6.3 Document Deferred
Medium/Low issues: document in TODO.md or code comments.

### 6.4 Summary Report
- Issue counts by category
- Fixed issues with descriptions
- Deferred issues with justification
- Build/test status
- Recommended follow-ups (`/cleanup`, `/performance`, `/deps`)

## Guidelines

- Understand context before flagging issues
- Only fix clear issues, avoid unnecessary refactoring
- Preserve behavior
- Test after fixing
- Trust agent confidence >=80
- Consider readability vs efficiency trade-offs
