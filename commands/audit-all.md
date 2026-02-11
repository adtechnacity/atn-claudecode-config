---
description: Run all audits (code, tests, docs, comments) in parallel waves
---

Run comprehensive audit of the entire codebase using a flat mega-team for maximum parallelism.

**Execute in two parallel waves. Fix Critical/High issues between waves.**

## Integration

Combines: `/audit-code`, `/audit-tests`, `/audit-docs`, `/audit-comments`, `/audit-deps`

Used by: `/ship` can use this instead of running individual audits

## Team Setup

```
# Clean up stale teams from previous runs
# Check ~/.claude/teams/ for audit-all-* directories and delete if found

TeamCreate(team_name: "audit-all-<YYYYMMDD-HHmmss>")
```

## Wave 1: Code + Dependencies (Parallel)

Spawn ALL Wave 1 agents as teammates in a single message. Use `model: "opus"` for all.

### Code Audit Agents

These agents follow the `/audit-code` workflow phases within the shared team (no sub-team). The lead orchestrates phases (dispatching phase 2 agents first, then 3, etc.) while the deps auditor runs independently alongside.

**Phase 2 agents** (spawn immediately):
- `"bug-reviewer"` (`subagent_type: "general-purpose"`) — Bug review per `/audit-code` Phase 2.1
- `"ts-reviewer"` (`subagent_type: "general-purpose"`, if TS) — TypeScript review per `/audit-code` Phase 2.2

**Phase 3 agents** (spawn after Phase 2, send cross-phase context):
- `"security-scanner"` (`subagent_type: "security-scanner"`) — Security audit per `/audit-code` Phase 3.1
- `"security-reviewer"` (`subagent_type: "general-purpose"`) — Security review per `/audit-code` Phase 3.2

**Phase 4 agents** (spawn after Phase 3, send cross-phase context):
- `"perf-analyzer"` (`subagent_type: "performance-analyzer"`) — Performance audit per `/audit-code` Phase 4.1
- `"hot-path-explorer"` (`subagent_type: "Explore"`) — Hot path tracing per `/audit-code` Phase 4.2

**Phase 5 agent** (spawn after Phase 4, send cross-phase context):
- `"quality-reviewer"` (`subagent_type: "general-purpose"`) — Quality review per `/audit-code` Phase 5.1

**Phase 6 agent** (spawn after Phase 5, send cross-phase context):
- `"reliability-reviewer"` (`subagent_type: "general-purpose"`) — Reliability review per `/audit-code` Phase 6.1

All code audit agents follow the `/audit-code` instructions for their phase: post findings via TaskCreate with metadata `{type: "finding", severity: "...", phase: N, files: [...]}`, check TaskList for prior findings, skip duplicates.

### Dependency Audit Agent (runs independently alongside code audit phases)

- `"deps-auditor"` (`subagent_type: "general-purpose"`) — Runs `/audit-deps` workflow independently
  > "Run a full dependency audit: security vulnerabilities, outdated packages, unused dependencies, license issues. Post each finding as a task via TaskCreate with metadata: `{type: 'finding', severity: 'Critical|High|Medium|Low', audit: 'deps', files: ['package.json']}`. **If you find CVEs, message `security-scanner` via SendMessage: 'CVE in [package]: [description] — check usage in code.'**"

Spawn `deps-auditor` in the same initial message as the Phase 2 code audit agents so it runs in parallel from the start.

### Wave 1 Coordination

- `deps-auditor` messages `security-scanner` when it finds CVEs for cross-referencing in code
- Code audit agents share findings per the `/audit-code` cross-phase pattern
- Lead orchestrates code audit phases (2 → 3 → 4 → 5 → 6) while deps-auditor runs independently

## Auto-Fix Gate

When Wave 1 completes (all code audit phases + deps audit):

1. **Review all findings** from TaskList (filter by `metadata.type: "finding"`)
2. **Auto-fix Critical/High issues** without pausing for user review
3. **Re-run validation**: typecheck, lint, test
4. **Summarize Wave 1**: Issue counts by audit type, what was fixed, what remains

## Wave 2: Tests + Docs + Comments (Parallel)

After the auto-fix gate, spawn Wave 2 agents on the same team in a single message. Send each a summary of Wave 1 results.

```
SendMessage(
  type: "message",
  recipient: "test-auditor",
  content: "Wave 1 code audit complete. Code was modified to fix these issues: [...]. Verify tests cover new changes. Focus: coverage gaps, redundant tests, test quality.",
  summary: "Wave 1 context for test audit"
)
# Same pattern for docs-auditor and comments-auditor
```

- `"test-auditor"` (`subagent_type: "general-purpose"`, `model: "opus"`) — Runs `/audit-tests` workflow
  > "Audit test coverage and quality. Wave 1 modified code to fix these issues: [...]. Verify tests cover new changes. Post findings via TaskCreate with metadata: `{type: 'finding', severity: '...', audit: 'tests'}`."

- `"docs-auditor"` (`subagent_type: "general-purpose"`, `model: "opus"`) — Runs `/audit-docs` workflow
  > "Audit documentation accuracy. Wave 1 modified code — verify docs reflect modifications. Post findings via TaskCreate with metadata: `{type: 'finding', severity: '...', audit: 'docs'}`."

- `"comments-auditor"` (`subagent_type: "general-purpose"`, `model: "opus"`) — Runs `/audit-comments` workflow
  > "Audit code comments. Wave 1 modified code — verify comments are accurate for changed files. Remove redundant comments, add missing explanations. Post findings via TaskCreate with metadata: `{type: 'finding', severity: '...', audit: 'comments'}`."

## Team Teardown

After Wave 2 completes:

```
# Shutdown all remaining agents
SendMessage(type: "shutdown_request", recipient: "bug-reviewer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "ts-reviewer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "security-scanner", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "security-reviewer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "perf-analyzer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "hot-path-explorer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "quality-reviewer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "reliability-reviewer", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "deps-auditor", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "test-auditor", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "docs-auditor", content: "All audits complete")
SendMessage(type: "shutdown_request", recipient: "comments-auditor", content: "All audits complete")

# After all confirm shutdown
TeamDelete()
```

## Summary Report

After all waves complete, provide:

| Audit | Issues Found | Fixed | Deferred |
|-------|--------------|-------|----------|
| Code - Bugs | - | - | - |
| Code - Security | - | - | - |
| Code - Performance | - | - | - |
| Code - Quality | - | - | - |
| Code - Reliability | - | - | - |
| Deps | - | - | - |
| Tests | - | - | - |
| Docs | - | - | - |
| Comments | - | - | - |

**Build Status**: Pass/Fail

**Recommended Follow-ups**: `/cleanup`, `/performance`

## Error Recovery

If a teammate crashes:
1. Its tasks remain — mark back to `pending` if needed
2. Other agents in the same wave continue unaffected
3. Optionally spawn a replacement on the same team
4. Note the gap in the summary report

See `workflows/parallel-dispatch.md` "Agent Teams" section for full team coordination patterns.
