---
description: Multi-agent debugging engine with hypothesis-driven root cause analysis
argument-hint: Error description, stack trace, or Sentry URL
---

# Debug Engine

Systematic, hypothesis-driven debugging with external intelligence (Sentry, DevTools, CloudWatch), parallel codebase investigation, and structured evidence chains.

## Integration

Related: **`/sentry-triage`** (bulk issue triage), **`/audit-code`** (code-level audit), **`/performance`** (performance profiling)

MCP: **sentry** (production errors), **chrome-devtools** (frontend), **aws-cloudwatch** (backend/infra)

---

## Phase 1: Gather Context (lead, no agents)

### 1.1 Collect Bug Information

Initial request: $ARGUMENTS

Gather from user (ask if not provided):

1. **Error/behavior** — What's happening? (error message, stack trace, Sentry URL, screenshot)
2. **Expected behavior** — What should happen instead?
3. **Reproduction steps** — How to trigger it?
4. **Recent changes** — What changed? (deploys, config, dependencies)
5. **Environment** — Where does it happen? (production, staging, local, browser, OS)

### 1.2 Detect Bug Category

Classify the bug to determine which external tools (Phase 2) and which verification agent (Phase 5) to use:

| Category | Signals | Phase 2 Tools | Phase 5 Agent |
|----------|---------|---------------|---------------|
| **production-error** | Sentry URL, 500 errors, crash reports | Sentry | general-purpose |
| **frontend** | UI broken, console errors, render issues | Chrome DevTools | general-purpose |
| **backend/infra** | API errors, timeouts, service failures | CloudWatch | general-purpose |
| **performance** | Slow responses, high CPU/memory, timeouts | CloudWatch + DevTools | performance-analyzer |
| **security** | Auth bypass, data exposure, injection | Sentry (if logged) | security-scanner |
| **logic** | Wrong output, incorrect calculations, bad state | None | general-purpose |
| **data** | Missing/corrupt data, query errors, migration issues | CloudWatch | general-purpose |

### 1.3 Build Bug Context Manifest

```markdown
## Bug Context Manifest

**Summary**: [one-line description]
**Category**: [from 1.2]
**Severity**: Critical | High | Medium | Low
**Environment**: [where it occurs]

### Error Details
- Error message: [exact text]
- Stack trace: [if available]
- Sentry URL: [if available]
- Affected users/requests: [scope of impact]

### Reproduction
1. [steps]

### Recent Changes
- [relevant commits, deploys, config changes]

### Initial Hypotheses
- [any obvious candidates from the error details]
```

This manifest is the context for all downstream agents.

---

## Phase 2: External Intelligence (lead, no agents)

Query external tools based on bug category. Skip tools not relevant to the category.

### 2.1 Sentry (if production-error, security, or error has a Sentry URL)

```
mcp__sentry__search_issues(organizationSlug, naturalLanguageQuery: "<error message or description>")
mcp__sentry__get_issue_details(organizationSlug, issueId)
mcp__sentry__analyze_issue_with_seer(organizationSlug, issueId)
mcp__sentry__search_issue_events(issueId, organizationSlug, naturalLanguageQuery: "from last 7 days in production")
```

Extract: stack trace, breadcrumbs, affected user count, frequency, environment, Seer root cause analysis.

**Note**: This is surgical investigation of the specific bug — NOT bulk triage (that's `/sentry-triage`'s job).

### 2.2 Chrome DevTools (if frontend)

```
mcp__chrome-devtools__list_console_messages()
mcp__chrome-devtools__list_network_requests()
mcp__chrome-devtools__take_screenshot()
```

For performance bugs, also:
```
mcp__chrome-devtools__performance_start_trace()
mcp__chrome-devtools__performance_stop_trace()
mcp__chrome-devtools__performance_analyze_insight()
```

Extract: console errors, failed network requests, visual state, performance bottlenecks.

### 2.3 CloudWatch (if backend/infra, performance, or data)

```
mcp__aws-cloudwatch__execute_log_insights_query(logGroupName, queryString: "fields @timestamp, @message | filter @message like /<error pattern>/ | sort @timestamp desc | limit 50", startTime, endTime)
mcp__aws-cloudwatch__get_active_alarms(region)
mcp__aws-cloudwatch__get_metric_data(metricDataQueries, startTime, endTime)
```

Extract: error logs with timestamps, active alarms, metric anomalies.

### 2.4 Build External Intelligence Summary

```markdown
## External Intelligence Summary

### Sentry (if queried)
- Issue: [title] (#[id]) — [count] events, [users] affected
- Stack trace: [key frames]
- Seer analysis: [root cause hypothesis]
- Pattern: [time-based, user-based, endpoint-based]

### DevTools (if queried)
- Console errors: [list]
- Failed requests: [list]
- Performance: [bottleneck description]

### CloudWatch (if queried)
- Error logs: [pattern description]
- Active alarms: [list]
- Metric anomalies: [description]

### Key Leads
1. [most promising lead from external data]
2. [second lead]
```

---

## Team Setup

Create the team before Phase 3. Phases 1-2 are lead-only and fast — no team needed until agents are required.

### Stale Cleanup

Check `~/.claude/teams/` for `debug-*` directories and delete if found.

### Create Team

```
TeamCreate(team_name: "debug-<YYYYMMDD-HHmmss>")
```

Initialize `hypothesis_attempts = 0` (tracked by lead for the Phase 4-5 loop).

---

## Phase 3: Codebase Investigation (2-3 Explore agents, parallel)

Spawn investigation agents as teammates in a single message. Each receives the Bug Context Manifest and External Intelligence Summary.

### 3.1 Error Tracer (always)

```
Task(subagent_type: "Explore", team_name: "debug-<ts>", name: "error-tracer", model: "opus",
  prompt: "You are an error tracer for a debugging investigation.

[BUG CONTEXT MANIFEST]
[EXTERNAL INTELLIGENCE SUMMARY]

Your job: trace the bug through the codebase and map the complete execution path.

1. **Stack trace mapping**: If a stack trace exists, verify every frame against actual code. Map file:line to current source.
2. **Call chain**: Trace the complete call chain from entry point (route/handler/event) through middleware, service layer, data layer. Document each hop.
3. **Data flow**: Track the specific data/state involved in the bug through each layer. Where does it transform? Where could it go wrong?
4. **Divergence point**: Identify exactly where actual behavior diverges from expected behavior.
5. **Error handling gaps**: Flag try/catch blocks that swallow errors, missing validation, unchecked return values along the path.

For each finding, post a task via TaskCreate:
  subject: '[Trace] <brief description>'
  description: Full details with file:line references
  metadata: {type: 'finding', category: 'trace', confidence: <0-100>, phase: 3, files: ['path']}

Only report findings with confidence >= 70.

Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'trace'}).")
```

### 3.2 Change Analyzer (always)

```
Task(subagent_type: "Explore", team_name: "debug-<ts>", name: "change-analyzer", model: "opus",
  prompt: "You are a change analyzer for a debugging investigation.

[BUG CONTEXT MANIFEST]
[EXTERNAL INTELLIGENCE SUMMARY]

Your job: analyze recent changes to find what might have introduced or exposed this bug.

1. **Recent commits**: Run `git log --oneline -30` and `git log --since='2 weeks ago' --oneline`. Identify commits touching files related to the bug.
2. **Diff analysis**: For suspicious commits, run `git show <hash>` to examine exact changes. Look for: removed error handling, changed logic, new code paths, dependency updates.
3. **Regression detection**: Compare current behavior against what the code did before suspicious changes. Use `git log -p --follow <file>` for key files.
4. **Dependency/config changes**: Check package.json/lock file changes, env var changes, config changes in the last 2 weeks.
5. **Deploy correlation**: If the bug started at a specific time, find what was deployed around then.

Before starting, check TaskList for findings from error-tracer. Focus on files they identified.

For each finding, post a task via TaskCreate:
  subject: '[Change] <brief description>'
  description: Full details with commit hash, file:line references
  metadata: {type: 'finding', category: 'change', confidence: <0-100>, phase: 3, files: ['path']}

Only report findings with confidence >= 70.

Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'change'}).")
```

### 3.3 Dependency Mapper (conditional — high-blast-radius bugs only)

Spawn this agent only when the bug affects shared code (utils, types, middleware, core services) or when the error spans multiple components.

```
Task(subagent_type: "Explore", team_name: "debug-<ts>", name: "dependency-mapper", model: "opus",
  prompt: "You are a dependency mapper for a debugging investigation.

[BUG CONTEXT MANIFEST]
[EXTERNAL INTELLIGENCE SUMMARY]

Your job: map the blast radius of the affected code to understand how far the bug could reach.

1. **Direct consumers**: For each file identified in the bug, find all files that import from it.
2. **Transitive consumers**: For high-impact files (shared utils, types, API routes), trace one more level.
3. **Consumer map**: Build a structured map: affected_file → [direct_consumers] → [transitive_consumers].
4. **Blast radius estimate**: Count total downstream consumers. Flag files with 10+ consumers.
5. **Cross-boundary impact**: Note if the bug crosses module/package/service boundaries.

Before starting, check TaskList for findings from error-tracer and change-analyzer.

Post the Consumer Map as a task:
  TaskCreate(subject: 'Consumer Map', description: '<full structured map>', metadata: {type: 'consumer-map', phase: 3})

For each high-blast-radius finding, post:
  TaskCreate(subject: '[Blast Radius] <brief description>', description: '...', metadata: {type: 'finding', category: 'blast-radius', confidence: <0-100>, phase: 3, files: ['path']})

Only report findings with confidence >= 70.")
```

### After Phase 3

1. Wait for all investigation agents to return.
2. Read all tasks from TaskList — collect findings, key files, and the Consumer Map (if created).
3. Read key files posted by agents to build deep understanding.
4. Shutdown investigation agents:

```
SendMessage(type: "shutdown_request", recipient: "error-tracer", content: "Investigation complete")
SendMessage(type: "shutdown_request", recipient: "change-analyzer", content: "Investigation complete")
# If spawned:
SendMessage(type: "shutdown_request", recipient: "dependency-mapper", content: "Investigation complete")
```

5. Build a **Phase 3 Summary** combining all investigation findings.

---

## Phase 4: Hypothesis Formation (lead, no agents)

### 4.1 Aggregate Evidence

Cross-reference External Intelligence (Phase 2) with Codebase Investigation (Phase 3):
- Do Sentry stack traces match the call chains traced by error-tracer?
- Do suspicious commits correlate with when the bug was first reported?
- Does the blast radius explain the scope of impact?

### 4.2 Form Hypotheses

Create top 3 hypotheses, each as a task with structured metadata:

```
TaskCreate(
  subject: "Hypothesis 1: [root cause summary]",
  description: "
    **Root cause**: [detailed explanation]
    **Evidence for**: [supporting findings with phase/file references]
    **Evidence against**: [contradicting evidence, if any]
    **Predicted fix**: [what the fix would look like]
    **Verification method**: [how to confirm — test, logging, reproduction]
    **Confidence**: [0-100]
  ",
  metadata: {type: "hypothesis", confidence: <0-100>, phase: 4, files: ["path"]}
)
```

### 4.3 Present to User

Present ranked hypotheses with evidence chains:

```markdown
## Hypotheses

### 1. [Most likely — confidence X%]
**Root cause**: ...
**Evidence**: [references to Phase 2/3 findings]
**Predicted fix**: ...

### 2. [Second — confidence Y%]
...

### 3. [Third — confidence Z%]
...
```

**ASK USER**: "Which hypothesis should I investigate first?" (or confirm the top-ranked one)

---

## Phase 5: Hypothesis Verification (1 specialized agent)

Spawn a single verification agent based on bug category. The agent receives the Bug Context Manifest, External Intelligence Summary, Phase 3 Summary, and the selected hypothesis.

### Agent Selection by Category

| Category | Agent Type | Verification Approach |
|----------|-----------|----------------------|
| production-error | general-purpose | Write failing test reproducing the bug, or add targeted logging |
| frontend | general-purpose | Reproduce in browser, inspect DOM/state, write test |
| backend/infra | general-purpose | Write failing test, check logs, trace request flow |
| performance | performance-analyzer | Profile the bottleneck, measure before/after |
| security | security-scanner | Investigate vulnerability, assess exploitability |
| logic | general-purpose | Write failing test that demonstrates wrong behavior |
| data | general-purpose | Inspect data patterns, query behavior, write test |

### Dispatch Verification Agent

```
Task(subagent_type: "<agent-type>", team_name: "debug-<ts>", name: "verifier", model: "opus",
  prompt: "You are verifying a debugging hypothesis.

[BUG CONTEXT MANIFEST]
[EXTERNAL INTELLIGENCE SUMMARY]
[PHASE 3 SUMMARY]

## Hypothesis to Verify
[Full hypothesis description from Phase 4]

Your job: confirm or refute this hypothesis with concrete evidence.

**Verification steps:**
1. Read the specific files and lines referenced in the hypothesis
2. [Category-specific]: Write a failing test / profile the code / scan for vulnerability / inspect data
3. Trace the exact execution path that triggers the bug
4. Determine if the hypothesis fully explains the observed behavior
5. Check for additional contributing factors

**Post your result as a task:**
TaskCreate(
  subject: 'Verification: [confirmed|refuted] — [hypothesis summary]',
  description: '
    **Result**: confirmed | refuted
    **Evidence**: [concrete proof — test output, profile data, code analysis]
    **If confirmed**: [exact root cause with file:line, proposed minimal fix]
    **If refuted**: [why the hypothesis doesn't hold, what the evidence actually points to]
  ',
  metadata: {type: 'verification', result: 'confirmed|refuted', phase: 5, files: ['path']}
)")
```

### After Verification

Read the verification result from TaskList.

**If confirmed**:
- Present the confirmed root cause and proposed fix to user
- **ASK USER**: "Root cause confirmed. Here's the proposed fix: [description]. Approve fix implementation?"
- If approved → proceed to Phase 6

**If refuted**:
- Increment `hypothesis_attempts`
- Shutdown verifier: `SendMessage(type: "shutdown_request", recipient: "verifier", content: "Verification complete")`
- **If `hypothesis_attempts` < 3** → return to Phase 4, present next hypothesis to user
- **If `hypothesis_attempts` >= 3** → trigger escalation (see below)

### Escalation: 3+ Refuted Hypotheses

If you've investigated 3 hypotheses and each was refuted:

1. **STOP** — don't attempt hypothesis #4
2. This pattern indicates a **deeper architectural or systemic issue**, not a simple bug
3. Present to user:
   - All 3 hypotheses and why each was refuted
   - What the evidence actually points to
   - Ask: "Is this pattern fundamentally sound, or are we fighting inertia?"
4. Consider: Is the problem in the architecture rather than the code?
5. Discuss with user before attempting more investigation

---

## Phase 6: Fix Implementation (1 general-purpose agent, after user approval)

Shutdown the verification agent (if not already shut down), then spawn a fix agent.

```
SendMessage(type: "shutdown_request", recipient: "verifier", content: "Verification complete")
```

```
Task(subagent_type: "general-purpose", team_name: "debug-<ts>", name: "fixer", model: "opus",
  prompt: "You are implementing a bug fix.

[BUG CONTEXT MANIFEST]
[CONFIRMED ROOT CAUSE — from Phase 5 verification]
[APPROVED FIX DESCRIPTION — from user approval]

Your job: implement the minimal fix, add a regression test, and validate.

**Steps:**
1. **Implement the minimal fix** — change only what's necessary to fix the root cause. Do not refactor surrounding code.
2. **Add regression test** — write a test that:
   - Would have caught this bug before the fix
   - Verifies the correct behavior after the fix
   - Tests the specific edge case that triggered the bug
3. **Remove debug code** — if any debug logging was added during investigation, remove it
4. **Validate** — run the test suite to ensure:
   - The new regression test passes
   - No existing tests break
   - Type checking passes
   - Linting passes

**Post your result as a task:**
TaskCreate(
  subject: 'Fix: [summary of change]',
  description: '
    **Files changed**: [list with brief description of each change]
    **Regression test**: [test file, test name, what it verifies]
    **Validation**: pass | fail (with details)
  ',
  metadata: {type: 'fix', phase: 6, validation: 'pass|fail', files: ['path']}
)")
```

### After Fix

1. Read fix result from TaskList
2. Shutdown fixer: `SendMessage(type: "shutdown_request", recipient: "fixer", content: "Fix complete")`
3. If validation failed, investigate failure and either fix or escalate to user

---

## Phase 7: Verification & Report (lead, no agents)

### 7.1 Final Verification

Run independently to verify the fix:

```bash
# Reproduce the original bug — verify it no longer occurs
# Run full test suite
npm test  # or project equivalent
# Typecheck
npm run typecheck  # or project equivalent
# Lint
npm run lint  # or project equivalent
```

### 7.2 Update Sentry (if applicable)

If the bug came from Sentry:

```
mcp__sentry__update_issue(organizationSlug, issueId, status: "resolved")
```

### 7.3 Generate Debug Report

Review all tasks from TaskList to build the evidence chain.

```markdown
## Debug Report

**Bug**: [summary] | **Category**: [type] | **Severity**: [level]

---

### Root Cause

[Detailed explanation with file:line references]

### Evidence Chain

| Phase | Source | Finding | Confidence |
|-------|--------|---------|------------|
| 2 | Sentry/DevTools/CloudWatch | [external intelligence finding] | — |
| 3 | error-tracer | [codebase finding] | X% |
| 3 | change-analyzer | [change finding] | X% |
| 4 | Hypothesis formation | [selected hypothesis] | X% |
| 5 | Verification | Confirmed — [evidence] | X% |

### Fix Applied

| File | Change | Reason |
|------|--------|--------|
| [path] | [description] | [why] |

### Regression Test

- **File**: [test file path]
- **Test**: [test name]
- **Verifies**: [what it checks]

### Validation

- [x] Bug no longer reproduces
- [x] Regression test passing
- [x] All tests pass
- [x] Typecheck + lint pass

### Prevention

[How to prevent similar issues — better validation, error handling, monitoring, etc.]

### Hypotheses Considered

| # | Hypothesis | Confidence | Result |
|---|-----------|------------|--------|
| 1 | [description] | X% | Confirmed / Refuted |
| 2 | [description] | Y% | Not tested / Refuted |
| 3 | [description] | Z% | Not tested / Refuted |
```

### 7.4 Team Teardown

```
# Shutdown any remaining agents (some may already be shut down)
# Only send to agents that haven't been shut down yet

# After all confirm shutdown
TeamDelete()
```

---

## Multi-Component Diagnostics

When debugging across system boundaries (CI → build → deploy, API → service → DB):

1. Add logging at **each component boundary** before proposing fixes
2. Log what enters and exits each layer
3. Run once to gather evidence showing **where** data breaks
4. Then investigate that specific component

---

## Red Flags — Return to Phase 3

Stop and re-investigate if you catch yourself:
- Proposing fixes without tracing data flow
- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- Adding multiple changes at once to "save time"
- "I don't fully understand but this might work"
- Previous hypothesis didn't hold and you're already forming the next one without new evidence

---

## Common Patterns

| Category | Check For |
|----------|-----------|
| Async | Missing `await`, race conditions, unhandled promise rejections, floating promises |
| State | Stale closures, timing issues, mutation of immutable state, stale cache |
| Types | null/undefined access, incorrect type guards, missing discriminated union cases |
| API | Request/response format mismatch, auth failures, CORS, timeout handling |
| Data | N+1 queries, missing indexes, stale cache, migration drift, constraint violations |
| Deploy | Config mismatch between environments, missing env vars, dependency version drift |

---

## Error Recovery

If a teammate crashes mid-phase:
1. Its tasks remain in `in_progress` — remaining agents in that phase still contribute findings
2. Continue with next phase (partial results are still valuable)
3. Optionally spawn a replacement agent on the same team
4. Note the gap in the Debug Report
5. See `workflows/parallel-dispatch.md` "Agent Teams" section for full team coordination patterns

---

## Options

- `/debug <error message>` — Debug from an error message or stack trace
- `/debug <sentry-url>` — Debug from a Sentry issue URL
- `/debug` — Describe the bug interactively
