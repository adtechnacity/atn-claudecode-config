---
description: Review an implementation plan for gaps, edge cases, and ambiguities
argument-hint: Path to plan file or paste plan inline
---

## Integration

Related: **`orchestration`** skill (`workflows/write-plan.md` creates plans, `workflows/orchestrate.md` builds task graphs), **`/feature-dev`** (guided development), **`/audit-code`** (code-level audit)

## Phase 1: Load & Parse Plan (lead, no agents)

### 1.1 Load the Plan

If a file path is provided, read it. Otherwise, ask the user to provide or paste the plan.

### 1.2 Build Plan Manifest

Parse the plan and extract a structured manifest:

```markdown
## Plan Manifest

**Goal**: [What the plan aims to accomplish]
**Approach**: [Proposed approach and key decisions]
**Scope**: [What's in, what's out]

### Files
- **Create**: [list of new files]
- **Modify**: [list of existing files to change]

### APIs & Schemas
- [API endpoints added/changed]
- [DB schema changes]
- [Event shapes / message contracts]

### Config & Environment
- [New env vars]
- [Config changes]
- [Feature flags]

### Dependencies
- [New packages/services]
- [External service integrations]

### Task Count & Structure
- [Number of tasks, dependency graph if present]
```

This manifest is the context for all downstream agents.

---

## Team Setup

### Stale Cleanup

Check `~/.claude/teams/` for `review-plan-*` directories and delete if found.

### Create Team

```
TeamCreate(team_name: "review-plan-<YYYYMMDD-HHmmss>")
```

---

## Phase 2: Deep Codebase Validation (2 Explore agents)

Spawn both explorers as teammates in a single message:

```
Task(subagent_type: "Explore", team_name: "review-plan-<ts>", name: "codebase-validator", model: "opus",
  prompt: "You are a codebase validator for a plan review.

[PLAN MANIFEST — full manifest from Phase 1]

Your job: validate every concrete reference in this plan against the actual codebase.

1. **File paths**: Verify every file path mentioned exists. Flag files listed as 'modify' that don't exist, or files listed as 'create' that already exist.
2. **Functions/classes**: Verify referenced functions, classes, methods, and exports are real and have the signatures the plan assumes.
3. **Imports**: Check that import paths the plan assumes are valid.
4. **Patterns**: Verify the plan follows existing codebase patterns (naming conventions, file organization, abstraction layers).
5. **CLAUDE.md conventions**: Check if the plan follows project conventions from CLAUDE.md.

For each finding, post a task via TaskCreate:
  subject: '[Validation] <brief description>'
  description: Full details with file:line references
  metadata: {type: 'finding', category: 'codebase-validation', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 2, files: ['path']}

Only report findings with confidence >= 75.
Also post key files you discover as tasks: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'validation'}).")

Task(subagent_type: "Explore", team_name: "review-plan-<ts>", name: "dependency-tracer", model: "opus",
  prompt: "You are a dependency tracer for a plan review.

[PLAN MANIFEST — full manifest from Phase 1]

Your job: trace the import/consumer graph for every file the plan modifies or creates.

1. **Direct consumers**: For each file the plan modifies, find all files that import from it.
2. **Transitive consumers**: For high-impact files (shared utils, types, API routes), trace one more level — who imports the importers?
3. **Consumer Map**: Build a structured map:
   - file_modified → [direct_consumers] → [transitive_consumers]
4. **Blast radius estimate**: For each modified file, count total downstream consumers. Flag files with 10+ consumers as high-blast-radius.
5. **Cross-boundary impacts**: Note if changes cross module/package boundaries.

Post the Consumer Map as a task:
  TaskCreate(subject: 'Consumer Map', description: '<full structured map>', metadata: {type: 'consumer-map', phase: 2})

For each high-blast-radius finding, post:
  TaskCreate(subject: '[Dependency] <brief description>', description: '...', metadata: {type: 'finding', category: 'dependency-trace', severity: 'High|Medium', confidence: <0-100>, phase: 2, files: ['path']})

Only report findings with confidence >= 75.
Also post key files as tasks: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'dependency'}).")
```

### After Phase 2

1. Wait for both explorers to return.
2. Read all tasks from TaskList — collect findings and the Consumer Map.
3. Read key files posted by explorers to build deep codebase understanding.
4. Shutdown explorers:

```
SendMessage(type: "shutdown_request", recipient: "codebase-validator", content: "Validation complete")
SendMessage(type: "shutdown_request", recipient: "dependency-tracer", content: "Tracing complete")
```

5. Build a **Phase 2 Summary** combining validation findings and the Consumer Map. This summary is sent to all Wave 1 agents.

---

## Phase 3–5: Wave 1 (3 agents in parallel)

Spawn all three Wave 1 agents as teammates in a single message. Each receives the Plan Manifest, Phase 2 Summary, and Consumer Map.

### Phase 3: Impact & Breaking Changes

```
Task(subagent_type: "general-purpose", team_name: "review-plan-<ts>", name: "impact-analyzer", model: "opus",
  prompt: "You are an impact and breaking change analyzer for a plan review.

[PLAN MANIFEST]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Analyze the plan for impact and breaking changes:

1. **Blast Radius Scoring**: Based on the Consumer Map, score overall blast radius:
   - Small: ≤5 direct consumers affected
   - Medium: 6-15 direct consumers affected
   - Large: 16-30 direct consumers affected
   - Critical: 30+ consumers or cross-service boundary

2. **Breaking Change Detection**: Check for:
   - API signature changes (parameters added/removed/retyped, response shape changes)
   - DB schema changes (column renames/drops, type changes, constraint changes)
   - Config/env key changes (renamed, removed, new required keys)
   - Event shape changes (payload structure, event names)
   - Export changes (removed/renamed exports that consumers depend on)
   - CLI/command interface changes

3. **Backwards Compatibility**: For each breaking change, assess:
   - Is a migration path specified in the plan?
   - Can old and new versions coexist during deployment?
   - Are there version boundaries or feature flags?

4. **Migration Assessment**: Rate migration complexity:
   - None needed
   - Simple (automated or single-step)
   - Complex (multi-step, requires coordination)
   - Dangerous (data loss risk, requires careful sequencing)

Before starting, check TaskList for existing Phase 2 findings. Skip already-reported issues.

Post each finding via TaskCreate:
  subject: '[Impact] <brief description>'
  description: Full details
  metadata: {type: 'finding', category: 'impact', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 3, files: ['path']}

Also post a summary task:
  TaskCreate(subject: 'Impact Summary', description: '<blast radius score, breaking changes list, migration assessment>', metadata: {type: 'phase-summary', phase: 3})

Only report findings with confidence >= 75.")
```

### Phase 4: Architecture & Complexity

```
Task(subagent_type: "general-purpose", team_name: "review-plan-<ts>", name: "architecture-reviewer", model: "opus",
  prompt: "You are an architecture and complexity reviewer for a plan review.

[PLAN MANIFEST]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Analyze the plan for architecture quality and complexity risks:

1. **Coupling Analysis**:
   - Does the plan introduce tight coupling between modules?
   - Are there circular dependency risks?
   - Does it respect existing module boundaries?

2. **Complexity Prediction**: For each file the plan modifies/creates, estimate:
   - Expected file size (will it exceed 300 lines?)
   - Function length (will any function exceed 50 lines?)
   - Nesting depth (will any block exceed 3 levels?)
   - God class/module risk (too many responsibilities?)

3. **Anti-Pattern Detection**:
   - Leaky abstractions (implementation details crossing boundaries)
   - Feature envy (code that should live in another module)
   - Shotgun surgery (single change requires touching many files)
   - Premature abstraction (abstractions without multiple consumers)
   - Parallel inheritance (changes in one hierarchy require changes in another)

4. **Pattern Consistency**:
   - Does the plan follow established codebase patterns?
   - Are there naming inconsistencies?
   - Does it reuse existing abstractions or create redundant ones?

Before starting, check TaskList for existing findings. Skip already-reported issues.

Post each finding via TaskCreate:
  subject: '[Architecture] <brief description>'
  description: Full details with file references
  metadata: {type: 'finding', category: 'architecture', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 4, files: ['path']}

Also post a summary task:
  TaskCreate(subject: 'Architecture Summary', description: '<coupling assessment, complexity predictions, anti-patterns found, pattern consistency>', metadata: {type: 'phase-summary', phase: 4})

Only report findings with confidence >= 75.")
```

### Phase 5: Security & Operational Risk

```
Task(subagent_type: "security-scanner", team_name: "review-plan-<ts>", name: "security-ops-reviewer", model: "opus",
  prompt: "You are a security and operational risk reviewer for a plan review.

[PLAN MANIFEST]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Analyze the plan for security vulnerabilities and operational readiness:

**Security:**
1. **Input validation**: Are all new user inputs validated? Missing sanitization?
2. **Auth/AuthZ**: Do new endpoints have proper authentication and authorization?
3. **Sensitive data**: Does the plan handle PII, tokens, secrets correctly? No logging of sensitive data?
4. **Injection vectors**: SQL injection, XSS, command injection, path traversal risks?
5. **Rate limiting**: Do new public endpoints need rate limiting?
6. **CORS/CSP**: Do changes affect cross-origin or content security policies?

**Operational:**
7. **Logging**: Are new code paths observable? Structured logging present?
8. **Monitoring**: Are there health checks, metrics, or alerting for new functionality?
9. **Error handling**: Are all error paths handled? No silent failures?
10. **Data safety**: Are DB operations in transactions where needed? Concurrent write protection? Idempotency for retryable operations?
11. **Resource limits**: Are there timeouts, connection limits, memory bounds for new operations?

Before starting, check TaskList for existing findings. Skip already-reported issues.

Post each finding via TaskCreate:
  subject: '[Security] <brief description>' or '[Ops] <brief description>'
  description: Full details with specific remediation
  metadata: {type: 'finding', category: 'security|operational', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 5, files: ['path']}

Also post a summary task:
  TaskCreate(subject: 'Security & Ops Summary', description: '<security posture assessment, operational readiness gaps>', metadata: {type: 'phase-summary', phase: 5})

Only report findings with confidence >= 75.")
```

### After Wave 1

1. Wait for all three Wave 1 agents to return.
2. Read all new tasks from TaskList — collect Phase 3-5 findings and summaries.
3. Build a **Wave 1 Summary** combining impact, architecture, and security findings. This is sent to the Wave 2 agent.

---

## Phase 6: Debt, Docs & Rollback (Wave 2, 1 agent)

This agent benefits from all prior findings.

```
Task(subagent_type: "general-purpose", team_name: "review-plan-<ts>", name: "debt-docs-reviewer", model: "opus",
  prompt: "You are a technical debt, documentation, and rollback reviewer for a plan review.

[PLAN MANIFEST]
[PHASE 2 SUMMARY]
[WAVE 1 SUMMARY — impact, architecture, security findings]

Analyze the plan for debt, documentation, and rollback concerns:

1. **Technical Debt Direction**:
   - Is this plan reducing, neutral to, or introducing technical debt?
   - Does it clean up existing debt or add to it?
   - Are there shortcuts that will need follow-up work?
   - Rate: Reducing / Neutral / Introducing

2. **Testing Strategy**:
   - Does the plan specify what tests to write?
   - Are critical paths covered?
   - Are edge cases from the impact analysis covered?
   - Is the test granularity appropriate (unit vs integration vs e2e)?
   - Missing test categories?

3. **Documentation Impact**:
   - Does the plan require README updates?
   - API documentation changes needed?
   - Architecture Decision Record (ADR) warranted?
   - CHANGELOG entry needed?
   - Migration guide for breaking changes (from Phase 3 findings)?

4. **Rollback Safety**:
   Based on all prior findings, score rollback safety:
   - **Safe**: Can revert the deploy with no data impact
   - **With-Migration**: Revert possible but requires a reverse migration
   - **Difficult**: Revert requires manual intervention or data repair
   - **Irreversible**: Data changes cannot be undone (destructive migrations, external side effects)

5. **Feature Flag Coverage**:
   - Should any changes be behind feature flags?
   - Can the feature be gradually rolled out?
   - Is there a kill switch for new functionality?

6. **Task Dependency Validation**:
   - Are task dependencies explicit and correct?
   - Is the execution order safe (schema before code, infra before features)?
   - Are there hidden dependencies (implicit file creation order)?
   - Is task granularity appropriate (2-5 minutes each)?
   - Can parallelizable work be identified?

Before starting, check TaskList for all existing findings. Skip already-reported issues. Build on prior analysis — don't repeat it.

Post each finding via TaskCreate:
  subject: '[Debt] ...' or '[Docs] ...' or '[Rollback] ...' or '[Testing] ...'
  description: Full details
  metadata: {type: 'finding', category: 'debt|docs|rollback|testing|task-deps', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 6, files: ['path']}

Also post a summary task:
  TaskCreate(subject: 'Debt/Docs/Rollback Summary', description: '<debt direction, test coverage assessment, doc gaps, rollback score, feature flag recommendations>', metadata: {type: 'phase-summary', phase: 6})

Only report findings with confidence >= 75.")
```

### After Wave 2

1. Wait for the agent to return.
2. Read all findings and the Phase 6 summary from TaskList.
3. Shutdown all remaining agents:

```
SendMessage(type: "shutdown_request", recipient: "impact-analyzer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "architecture-reviewer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "security-ops-reviewer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "debt-docs-reviewer", content: "Review complete")
```

---

## Phase 7: Synthesis, Scoring & Report (lead, no agents)

### 7.1 Aggregate Findings

Review all tasks from TaskList with `metadata.type: "finding"`. Deduplicate findings that overlap across phases (same file + same issue = keep higher-severity version).

### 7.2 Compute Risk Scores

**Per-finding risk score:**
```
risk = severity_weight × confidence / 100
```

| Severity | Weight |
|----------|--------|
| Critical | 100 |
| High | 75 |
| Medium | 50 |
| Low | 25 |

**Overall Plan Risk Score (0-100):**
1. Sum all per-finding risk scores
2. Normalize to 0-100 scale based on plan scope (more tasks = higher tolerance)
3. Apply blast radius multiplier:
   - Small: ×1.0
   - Medium: ×1.1
   - Large: ×1.25
   - Critical: ×1.5

### 7.3 Determine Verdict

| Verdict | Criteria |
|---------|----------|
| **APPROVE** | Risk 0-25, no Critical/High findings, rollback safe |
| **APPROVE WITH CHANGES** | Risk 26-50, no Critical findings, addressable High findings |
| **REVISE** | Risk 51-75, Critical findings present or multiple High |
| **REJECT** | Risk 76+, fundamental approach issues |

### 7.4 Generate Report

```markdown
## Plan Review: [Plan Name]

**Verdict**: APPROVE | APPROVE WITH CHANGES | REVISE | REJECT
**Risk Score**: X/100 | **Blast Radius**: S/M/L/C | **Debt**: Reducing/Neutral/Introducing | **Rollback**: Safe/With-Migration/Difficult/Irreversible

---

### Risk Dashboard

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Codebase Validation | | | | |
| Impact & Breaking Changes | | | | |
| Architecture & Complexity | | | | |
| Security & Operational | | | | |
| Debt, Docs & Rollback | | | | |
| **Total** | | | | |

---

### Critical Findings (Must Address)

| # | Finding | Category | Confidence | Files | Suggested Fix |
|---|---------|----------|------------|-------|---------------|

### High-Priority Findings

| # | Finding | Category | Confidence | Files | Suggested Fix |
|---|---------|----------|------------|-------|---------------|

<details>
<summary>Medium/Low Findings (N items)</summary>

| # | Finding | Category | Severity | Confidence | Files |
|---|---------|----------|----------|------------|-------|

</details>

---

### Breaking Changes Detected

| # | Change | Type | Migration Path | Risk |
|---|--------|------|----------------|------|

### Architecture Assessment

[Summary from Phase 4: coupling, complexity predictions, anti-patterns, pattern consistency]

### Rollback Assessment

[Summary from Phase 6: rollback safety score with justification]

---

### Questions for Clarification

1. [Specific question about ambiguous requirement]
2. [Question about intended behavior in edge case]

### What's Good

- [Strengths of the plan worth preserving]
- [Good architectural decisions]
- [Risks the plan already mitigates]

### Recommended Plan Modifications

1. [Specific modification with rationale]
2. [Additional task or step to add]
3. [Edge case handling to include]
```

### 7.5 Present and Ask Questions

Present the full report. If there are clarifying questions, **wait for answers** before suggesting plan updates.

---

## Phase 8: Suggest Updates & Handoff

### 8.1 Suggest Updates

Based on user answers and findings, propose specific edits:

- New tasks or steps to add
- Existing steps to modify
- Edge case handling to include
- Tests to add
- Breaking change mitigations

**ASK USER**: "Would you like me to apply these updates to the plan file?"

If yes, edit the plan file directly.

### 8.2 Execution Handoff

After updates are applied (or if no updates needed):

**ASK USER**: "Plan review complete. Ready to execute?"

If yes, proceed to the orchestration skill's `workflows/orchestrate.md` to break the plan into a prioritized task graph with dependencies and execute using Claude Tasks and Team Agents.

---

## Team Teardown

After Phase 7 report is generated:

```
# Shutdown any remaining agents (some may already be shut down)
# Only send to agents that haven't been shut down yet

# After all confirm shutdown
TeamDelete()
```

## Error Recovery

If a teammate crashes mid-phase:
1. Log the failure — remaining agents in that phase still contribute findings
2. Continue with next phase (partial results are still valuable)
3. Optionally spawn a replacement agent on the same team
4. Note the gap in the summary report
5. Adjust risk score confidence downward for the affected category

## Options

- `/review-plan <path>` — Review a plan file
- `/review-plan` — Paste or describe a plan to review
