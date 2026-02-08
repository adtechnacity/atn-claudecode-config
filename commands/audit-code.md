---
description: Audit codebase for performance, security, and maintainability issues
---

Comprehensive code audit focused on improving existing code, not adding features.

## Integration

Used by: **`/ship`** (Phase 1), **`/commit`** (manual)

Related: **`/cleanup`**, **`/performance`**, **`/deps`**

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

## Phase 2: Bug Review

### 2.1 Code Reviewer - Bugs (`subagent_type: "general-purpose"`)
> "You are an expert code reviewer. Review for bugs: logic errors, null/undefined handling, race conditions, edge cases, off-by-one errors. Rate each issue with confidence 0-100, only report >= 80. For each issue provide: confidence score, file:line, clear description, specific fix suggestion. Group by severity (Critical vs Important)."

### 2.2 TypeScript-Specific Review (if applicable)

For TypeScript/React/Node.js codebases, launch (`subagent_type: "general-purpose"`):
> "You are a senior TypeScript/React/Node.js engineer. Production readiness review covering: type safety (no `any`, proper generics, discriminated unions), React patterns (re-render risks, hook deps, error boundaries, a11y), Node.js (async error handling, input validation, no floating promises), and production concerns (graceful degradation, structured logging, bundle size). Rate confidence 0-100, only report >= 80."

## Phase 3: Security Audit

### 3.1 Security Scanner Agent (`subagent_type: "general-purpose"`)
> "Perform security audit: OWASP Top 10, secret detection, dependency CVEs. Rate each finding with confidence 0-100, only report >= 80. Include file:line and specific remediation."

### 3.2 Code Reviewer - Security (`subagent_type: "general-purpose"`)
> "Review for XSS, injection, insecure data handling, permission issues. Focus on auth code, API handlers, user input. Rate confidence 0-100, only report >= 80."

### 3.3 Manual Checks
Credential storage, config permissions, API key exposure, input validation.

### 3.4 Merge Findings
Combine agent issues (>=80 confidence) with manual findings. Classify by severity.

## Phase 4: Performance Audit

### 4.1 Performance Analyzer (`subagent_type: "Explore"`)
> "Analyze bottlenecks, Core Web Vitals, bundle sizes, render performance. Include file:line references."

Or run `/performance` command.

### 4.2 Code Explorer - Hot Paths (`subagent_type: "Explore"`)
> "Trace hot paths: performance-critical sections, frequently called functions, data pipelines, execution flows. Follow call chains and note data transformations at each step."

### 4.3 Analyze Hot Paths
Check for: O(n^2)+ algorithms, missing early returns, repeated computations, large non-streaming operations.

### 4.4 Memory and Async
Check for: large data held unnecessarily, uncleaned listeners/subscriptions, sequential awaits (parallelize), missing async error handling.

### 4.5 Build Output
Run production build, check bundle sizes and unused code.

## Phase 5: Maintainability Audit

### 5.1 Code Reviewer - Quality (`subagent_type: "general-purpose"`)
> "Review for duplication, complexity, type safety, project conventions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix."

### 5.2 Manual Checks
Functions >50 lines or >3 nesting levels, unused exports/dead code, unjustified weak typing, magic numbers.

### 5.3 Merge Findings
Use `/cleanup` for dead code removal.

## Phase 6: Reliability Audit

### 6.1 Code Reviewer - Reliability (`subagent_type: "general-purpose"`)
> "Review for error handling gaps, null handling, edge cases, race conditions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix."

### 6.2 Manual Checks
External API error handling, resource cleanup, graceful degradation, retry logic/timeouts.

## Phase 7: Fixes and Reporting

### 7.1 Categorize Issues
- **Critical**: Security/data loss - fix immediately
- **High**: Performance/reliability bug - fix soon
- **Medium**: Maintainability/minor bug - fix when convenient
- **Low**: Style/minor improvement - backlog

### 7.2 Apply Fixes
For Critical/High: create fix, verify no regressions, run checks.

### 7.3 Document Deferred
Medium/Low issues: document in TODO.md or code comments.

### 7.4 Summary Report
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
