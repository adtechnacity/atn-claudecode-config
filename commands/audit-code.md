---
description: Audit codebase for performance, security, and maintainability issues
---

Perform a comprehensive code audit. Focus on improving the existing codebase, not adding new features.

## Integration

This command is used by:
- **`/ship`** (Phase 1) - Mandatory audit before production release
- **`/commit`** - Can be run manually before committing

Related commands:
- **`/cleanup`** - Remove dead code identified during audit
- **`/perf`** - Deep dive into performance issues
- **`/deps`** - Manage dependencies identified as outdated/vulnerable
- **`/review`** - Review specific files or changes

## Build System Detection

Detect the project's build system and run appropriate commands:

| Indicator | Build System | Type Check | Lint | Test | Build |
|-----------|--------------|------------|------|------|-------|
| `package.json` | npm/Node.js | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | Elixir/Mix | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | Rust/Cargo | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | Python | `mypy .` | `ruff check .` | `pytest` | N/A |

If a script/command is not available (e.g., no `typecheck` script), skip that check.

## Agent Integration

This audit uses multiple agents for comprehensive analysis:

| Agent | Phase | Purpose |
|-------|-------|---------|
| `feature-dev:code-explorer` | Performance | Map hot paths and execution flows |
| `feature-dev:code-reviewer` | Security, Maintainability, Reliability | Review with confidence scoring (≥80 threshold) |
| `security-scanner` | Security | OWASP Top 10, CVE scanning, secret detection |
| `performance-analyzer` | Performance | Core Web Vitals, bottleneck identification |

Spawn agents via the Task tool with appropriate `subagent_type`.

## Phase 1: Static Analysis

### 1.1 Run Automated Checks

Run the project's type checker, linter, and tests using the detected build system.

Document any failures or warnings as immediate issues.

### 1.2 Check Dependencies

Use `/deps audit` or run directly:
- npm: `npm outdated` and `npm audit`
- mix: `mix hex.outdated` and `mix deps.audit`
- cargo: `cargo outdated` and `cargo audit`
- pip: `pip list --outdated` and `pip-audit`

Flag major version updates, security advisories, and unused dependencies.

**Tip:** Run `/deps` command for comprehensive dependency management.

## Phase 2: Security Audit

### 2.1 Spawn Security Scanner Agent

For comprehensive security analysis, use the `security-scanner` agent:
> "Perform a security audit focusing on OWASP Top 10 vulnerabilities, secret detection, and dependency CVEs."

### 2.2 Spawn Code Reviewer (Security Focus)

Launch `feature-dev:code-reviewer` with prompt:
> "Review for security vulnerabilities: XSS, injection, insecure data handling, permission issues. Focus on authentication code, API handlers, and user input processing."

### 2.3 Manual Security Checks

Items agents may miss (check based on project type):
- Credential storage and handling
- Configuration file permissions
- API key exposure
- Input validation at boundaries

### 2.4 Merge Findings

Combine agent issues (≥80 confidence) with manual findings. Classify by severity.

## Phase 3: Performance Audit

### 3.1 Use Performance Analyzer Agent

For deep performance analysis, use the `performance-analyzer` agent:
> "Analyze performance bottlenecks, Core Web Vitals, bundle sizes, and render performance."

Or run `/perf` command for interactive performance analysis.

### 3.2 Map Hot Paths with Code Explorer

Launch `feature-dev:code-explorer` with prompt:
> "Trace the hot paths in this codebase. Identify performance-critical sections, frequently called functions, and data processing pipelines. Map execution flows."

### 3.3 Analyze Identified Hot Paths

For each hot path the agent identified:
- Check for O(n²) or worse algorithms
- Look for missing early returns/short circuits
- Identify repeated computations that could be cached
- Find large data operations that could be streaming

### 3.4 Memory and Async Analysis

- Large data structures held unnecessarily
- Event listeners or subscriptions not cleaned up
- Sequential awaits that could be parallelized
- Missing error handling on async operations

### 3.5 Build Output

Run the production build and check output for bundle sizes, unused code, or bloat.

## Phase 4: Maintainability Audit

### 4.1 Spawn Code Reviewer (Quality Focus)

Launch `feature-dev:code-reviewer` with prompt:
> "Review for code quality: check for code duplication, complexity, type safety issues, and adherence to project conventions in CLAUDE.md or similar."

### 4.2 Manual Maintainability Checks

Items requiring manual review:
- Functions > 50 lines or nested > 3 levels
- Unused exports and dead code (consider `/cleanup` command)
- Weak typing (any, untyped, dynamic) without justification
- Magic numbers without named constants

### 4.3 Merge Findings

Combine agent issues with manual findings.

**Tip:** Use `/cleanup` command to remove identified dead code.

## Phase 5: Reliability Audit

### 5.1 Spawn Code Reviewer (Reliability Focus)

Launch `feature-dev:code-reviewer` with prompt:
> "Review for reliability issues: error handling gaps, null/undefined handling, edge cases, race conditions in concurrent operations."

### 5.2 Manual Reliability Checks

Project-specific concerns:
- External API error handling
- Resource cleanup (files, connections, timers)
- Graceful degradation on failures
- Retry logic and timeouts

### 5.3 Merge Findings

Combine agent issues with manual findings.

## Phase 6: Fixes and Reporting

### 6.1 Categorize All Issues

- **Critical**: Security vulnerability or data loss risk - fix immediately
- **High**: Performance regression or reliability bug - fix soon
- **Medium**: Maintainability issue or minor bug - fix when convenient
- **Low**: Style inconsistency or minor improvement - backlog

### 6.2 Apply Fixes

For Critical and High issues:
1. Create a fix
2. Verify no regressions
3. Run type check, tests, and build

### 6.3 Document Deferred Issues

For Medium and Low issues not fixed, document in TODO.md or as code comments.

### 6.4 Summary Report

Provide:
- Issues found by category (Critical/High/Medium/Low counts)
- Issues fixed with brief descriptions
- Issues deferred with justification
- Build/test status after fixes
- Recommended follow-up commands (`/cleanup`, `/perf`, `/deps`)

## Guidelines

- **Read before judging**: Understand context before flagging issues
- **Minimize changes**: Only fix clear issues, don't refactor unnecessarily
- **Preserve behavior**: Fixes should not change functionality
- **Test after fixing**: Verify fixes don't break existing tests
- **Trust agent confidence**: Issues with ≥80 confidence are likely real
- **Consider trade-offs**: Sometimes "inefficient" code is more readable
