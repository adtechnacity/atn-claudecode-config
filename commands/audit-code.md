---
description: Audit codebase for performance, security, and maintainability issues
---

Comprehensive code audit focused on improving existing code, not adding features.

## Integration

Used by: **`/ship`** (Phase 1), **`/commit`** (manual), **`/audit-all`** (Wave 1)

Related: **`/cleanup`**, **`/performance`**

## Build System Detection

| Indicator | Type Check | Lint | Test | Build |
|-----------|------------|------|------|-------|
| `package.json` | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | `mypy .` | `ruff check .` | `pytest` | N/A |

Skip unavailable commands.

## Team Setup

Before Phase 2, set up the agent team for cross-phase coordination.

**Detect mode:** Check if already running inside an `/audit-all` team (a team context already exists).

### Standalone Mode (not inside `/audit-all`)

```
# Clean up stale teams from previous runs
# Check ~/.claude/teams/ for audit-code-* directories and delete if found

TeamCreate(team_name: "audit-code-<YYYYMMDD-HHmmss>")
```

Spawn all agents as teammates (all in a single message for parallel start):
- **Phase 2**: `"bug-reviewer"` (general-purpose), `"ts-reviewer"` (general-purpose, if TS)
- **Phase 3**: `"security-scanner"` (security-scanner agent), `"security-reviewer"` (general-purpose)
- **Phase 4**: `"perf-analyzer"` (performance-analyzer agent), `"hot-path-explorer"` (Explore)
- **Phase 5**: `"quality-reviewer"` (general-purpose)
- **Phase 6**: `"reliability-reviewer"` (general-purpose)

Use `model: "opus"` for all agents.

### Inside `/audit-all` Mode

Skip TeamCreate — the parent team already exists. Agents are spawned by the `/audit-all` lead. Proceed directly to Phase 1.

## Phase 1: Static Analysis

### 1.1 Run Automated Checks
Run type checker, linter, and tests. Document failures/warnings.

### 1.2 Check Dependencies

Run `/audit-deps` to completion. Flag major updates, security advisories, unused dependencies.

## Phase 2: Bug Review

**Send to agents**: Assign tasks via TaskCreate + TaskUpdate(owner: ...).

### 2.1 Code Reviewer - Bugs (teammate: `"bug-reviewer"`, `subagent_type: "general-purpose"`)
> "You are an expert code reviewer. Review for bugs: logic errors, null/undefined handling, race conditions, edge cases, off-by-one errors. Rate each issue with confidence 0-100, only report >= 80. For each issue provide: confidence score, file:line, clear description, specific fix suggestion. Group by severity (Critical vs Important). **Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 2, files: ['path']}`**."

### 2.2 TypeScript-Specific Review (if applicable)

For TypeScript/React/Node.js codebases, launch teammate `"ts-reviewer"` (`subagent_type: "general-purpose"`):
> "You are a senior TypeScript/React/Node.js engineer. Production readiness review covering: type safety (no `any`, proper generics, discriminated unions), React patterns (re-render risks, hook deps, error boundaries, a11y), Node.js (async error handling, input validation, no floating promises), and production concerns (graceful degradation, structured logging, bundle size). Rate confidence 0-100, only report >= 80. **Before starting, check TaskList for findings from bug-reviewer. Skip issues already reported. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 2, files: ['path']}`**."

## Phase 3: Security Audit

**Cross-phase context**: Before dispatching Phase 3 agents, send them a summary of Phase 2 findings:
```
SendMessage(
  type: "message",
  recipient: "security-scanner",
  content: "Phase 2 found N issues in these files: [...]. Key themes: [...]. Focus extra attention on flagged files. Skip already-reported issues. Check TaskList for existing findings.",
  summary: "Phase 2 findings context"
)
# Same message to "security-reviewer"
```

### 3.1 Security Scanner Agent (teammate: `"security-scanner"`, `subagent_type: "security-scanner"`)
> "Perform security audit: OWASP Top 10, secret detection, dependency CVEs. Rate each finding with confidence 0-100, only report >= 80. Include file:line and specific remediation. **Before starting, check TaskList for findings from previous phases. Focus extra attention on flagged files. Skip issues already reported. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 3, files: ['path']}`**."

### 3.2 Code Reviewer - Security (teammate: `"security-reviewer"`, `subagent_type: "general-purpose"`)
> "Review for XSS, injection, insecure data handling, permission issues. Focus on auth code, API handlers, user input. Rate confidence 0-100, only report >= 80. **Before starting, check TaskList for findings from previous phases. Skip issues already reported. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 3, files: ['path']}`**."

### 3.3 Manual Checks
Credential storage, config permissions, API key exposure, input validation.

### 3.4 Merge Findings
Combine agent issues (>=80 confidence) with manual findings. Classify by severity.

## Phase 4: Performance Audit

**Cross-phase context**: Send Phase 2-3 findings summary to Phase 4 agents via SendMessage.

### 4.1 Performance Analyzer (teammate: `"perf-analyzer"`, `subagent_type: "performance-analyzer"`)
> "Analyze bottlenecks, Core Web Vitals, bundle sizes, render performance. Include file:line references. **Check TaskList for findings from previous phases. Focus extra attention on flagged files. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 4, files: ['path']}`**."

Or run `/performance` command.

### 4.2 Code Explorer - Hot Paths (teammate: `"hot-path-explorer"`, `subagent_type: "Explore"`)
> "Trace hot paths: performance-critical sections, frequently called functions, data pipelines, execution flows. Follow call chains and note data transformations at each step. **Check TaskList for context from previous phases. Post key findings as tasks via TaskCreate with metadata: `{type: 'finding', severity: 'Medium|Low', phase: 4, files: ['path']}`**."

### 4.3 Analyze Hot Paths
Check for: O(n^2)+ algorithms, missing early returns, repeated computations, large non-streaming operations.

### 4.4 Memory and Async
Check for: large data held unnecessarily, uncleaned listeners/subscriptions, sequential awaits (parallelize), missing async error handling.

### 4.5 Build Output
Run production build, check bundle sizes and unused code.

## Phase 5: Maintainability Audit

**Cross-phase context**: Send Phase 2-4 findings summary to Phase 5 agent via SendMessage.

### 5.1 Code Reviewer - Quality (teammate: `"quality-reviewer"`, `subagent_type: "general-purpose"`)
> "Review for duplication, complexity, type safety, project conventions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix. **Before starting, check TaskList for findings from previous phases. Skip issues already reported. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 5, files: ['path']}`**."

### 5.2 Manual Checks
Functions >50 lines or >3 nesting levels, unused exports/dead code, unjustified weak typing, magic numbers.

### 5.3 Merge Findings
Use `/cleanup` for dead code removal.

## Phase 6: Reliability Audit

**Cross-phase context**: Send Phase 2-5 findings summary to Phase 6 agent via SendMessage.

### 6.1 Code Reviewer - Reliability (teammate: `"reliability-reviewer"`, `subagent_type: "general-purpose"`)
> "Review for error handling gaps, null handling, edge cases, race conditions. Rate confidence 0-100, only report >= 80. Include file:line and specific fix. **Before starting, check TaskList for findings from previous phases. Skip issues already reported. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', phase: 6, files: ['path']}`**."

### 6.2 Manual Checks
External API error handling, resource cleanup, graceful degradation, retry logic/timeouts.

## Phase 7: Fixes and Reporting

### 7.1 Categorize Issues
Review all findings from TaskList (filter by `metadata.type: "finding"`).
- **Critical**: Security/data loss - fix immediately
- **High**: Performance/reliability bug - fix soon
- **Medium**: Maintainability/minor bug - fix when convenient
- **Low**: Style/minor improvement - backlog

### 7.2 Apply Fixes
For Critical/High: create fix, verify no regressions, run checks.

### 7.3 Document Deferred
Medium/Low issues: document in TODO.md or code comments.

### 7.4 Summary Report
- Issue counts by category (from TaskList findings)
- Fixed issues with descriptions
- Deferred issues with justification
- Build/test status
- Recommended follow-ups (`/cleanup`, `/performance`)

## Team Teardown (Standalone Mode Only)

If running standalone (not inside `/audit-all`):
```
# Shutdown all agents
SendMessage(type: "shutdown_request", recipient: "bug-reviewer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "ts-reviewer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "security-scanner", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "security-reviewer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "perf-analyzer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "hot-path-explorer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "quality-reviewer", content: "Audit complete")
SendMessage(type: "shutdown_request", recipient: "reliability-reviewer", content: "Audit complete")

# After all confirm shutdown
TeamDelete()
```

If inside `/audit-all`: skip teardown — the parent team handles it.

## Error Recovery

If a teammate crashes mid-phase:
1. Log the failure — remaining agents in that phase still contribute findings
2. Continue with next phase (partial results are still valuable)
3. Optionally spawn a replacement agent on the same team
4. Note the gap in the summary report

## Guidelines

- Understand context before flagging issues
- Only fix clear issues, avoid unnecessary refactoring
- Preserve behavior
- Test after fixing
- Trust agent confidence >=80
- Consider readability vs efficiency trade-offs
- See `workflows/parallel-dispatch.md` "Agent Teams" section for team coordination patterns
