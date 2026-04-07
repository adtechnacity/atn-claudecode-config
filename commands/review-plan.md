---
description: Review an implementation plan for gaps, edge cases, and ambiguities
argument-hint: Path to plan file or paste plan inline
---

## Integration

Related: **`/review-code`** (CodeRabbit-style code review)

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

## Phase 2: Codebase Grounding (1 Explore agent)

One explorer validates that the plan's references are grounded in reality:

```
Task(subagent_type: "Explore", team_name: "review-plan-<ts>", name: "codebase-scout", model: "opus",
  prompt: "You are a codebase scout for a plan review.

[PLAN MANIFEST — full manifest from Phase 1]

Your job: quickly validate the plan's assumptions against the actual codebase.

1. **File paths**: Verify files listed as 'modify' exist. Flag files listed as 'create' that already exist.
2. **Key patterns**: Check if the plan follows existing codebase conventions (naming, file organization, abstraction layers).
3. **CLAUDE.md conventions**: Check if the plan follows project conventions.
4. **Existing solutions**: Check if any functionality the plan creates already exists in the codebase (duplication risk).
5. **Integration points**: Verify the APIs, functions, or modules the plan intends to integrate with actually exist and have the expected interfaces.

Post each finding as a task via TaskCreate:
  subject: '[Grounding] <brief description>'
  description: Full details with file:line references
  metadata: {type: 'finding', category: 'grounding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 2}

Only report findings with confidence >= 75.")
```

### After Phase 2

1. Wait for the explorer to return.
2. Read all tasks from TaskList — collect grounding findings.
3. Shutdown the explorer:

```
SendMessage(type: "shutdown_request", recipient: "codebase-scout", content: "Grounding complete")
```

4. Build a **Grounding Summary** for Phase 3 agents.

---

## Phase 3: Plan Quality Review (2 agents in parallel)

Spawn both agents as teammates in a single message:

### 3.1 Completeness & Gaps Analyzer

```
Task(subagent_type: "general-purpose", team_name: "review-plan-<ts>", name: "completeness-analyzer", model: "opus",
  prompt: "You are a plan completeness and gaps analyzer.

[PLAN MANIFEST]
[GROUNDING SUMMARY — Phase 2 findings]

Analyze the plan for completeness, gaps, and ambiguity:

1. **Missing Steps**: Are there logical steps the plan skips?
   - Implied but unstated prerequisites
   - Steps between tasks that need explicit handling
   - Setup/teardown/cleanup not mentioned
   - Data migration or backfill steps

2. **Ambiguous Requirements**: Flag anything that could be interpreted multiple ways:
   - Vague descriptions ('handle errors appropriately', 'add validation')
   - Unspecified behavior for edge cases
   - Missing acceptance criteria
   - Undefined terms or unclear scope boundaries

3. **Edge Cases & Error Scenarios**: What does the plan NOT address?
   - Failure modes for each operation
   - Concurrent access scenarios
   - Empty/null/malformed input handling
   - Partial failure and recovery
   - Rate limits, timeouts, resource exhaustion

4. **Testing Strategy**:
   - Does the plan specify what tests to write?
   - Are critical paths covered?
   - Is test granularity appropriate (unit vs integration vs e2e)?
   - Missing test categories?

5. **Documentation Impact**:
   - README updates needed?
   - API documentation changes?
   - Migration guide for breaking changes?
   - CHANGELOG entry needed?

Before starting, check TaskList for Phase 2 findings. Build on them — don't repeat.

Post each finding via TaskCreate:
  subject: '[Gaps] <brief description>'
  description: Full details
  metadata: {type: 'finding', category: 'completeness', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 3}

Only report findings with confidence >= 75.")
```

### 3.2 Risk & Feasibility Assessor

```
Task(subagent_type: "general-purpose", team_name: "review-plan-<ts>", name: "risk-assessor", model: "opus",
  prompt: "You are a risk and feasibility assessor for a plan review.

[PLAN MANIFEST]
[GROUNDING SUMMARY — Phase 2 findings]

Assess the plan for risks, feasibility, and execution concerns:

1. **Breaking Changes**:
   - Does the plan introduce breaking changes?
   - Is a migration path specified?
   - Can old and new versions coexist during deployment?
   - Are there version boundaries or feature flags?

2. **Rollback Safety**:
   - Can the changes be reverted safely?
   - Are there irreversible operations (destructive migrations, external side effects)?
   - Score: Safe / With-Migration / Difficult / Irreversible

3. **Scope Assessment**:
   - Is the plan over-scoped? (doing too much in one change)
   - Is it under-scoped? (missing critical pieces that will break without them)
   - Could it be split into smaller, independently shippable increments?

4. **Technical Debt Direction**:
   - Is this plan reducing, neutral to, or introducing technical debt?
   - Are there shortcuts that will need follow-up work?

5. **Dependency & Sequencing Risks**:
   - Are external dependencies (APIs, services, packages) reliable and available?
   - Is the execution order safe? (schema before code, infra before features)
   - Are there hidden dependencies between tasks?
   - Could any tasks be parallelized?

6. **Task Structure**:
   - Are tasks right-sized (2-5 minutes each for agents)?
   - Are dependencies explicit and correct?
   - Is the execution order safe?
   - Can parallelizable work be identified?

Before starting, check TaskList for existing findings. Skip already-reported issues.

Post each finding via TaskCreate:
  subject: '[Risk] <brief description>'
  description: Full details
  metadata: {type: 'finding', category: 'risk', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 3}

Also post a summary task:
  TaskCreate(subject: 'Risk Summary', description: '<breaking changes, rollback score, scope assessment, debt direction, sequencing risks>', metadata: {type: 'phase-summary', phase: 3})

Only report findings with confidence >= 75.")
```

### After Phase 3

1. Wait for both agents to return.
2. Read all findings and summaries from TaskList.
3. Shutdown agents:

```
SendMessage(type: "shutdown_request", recipient: "completeness-analyzer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "risk-assessor", content: "Review complete")
```

---

## Phase 4: Synthesis & Report (lead, no agents)

### 4.1 Aggregate Findings

Review all tasks from TaskList with `metadata.type: "finding"`. Deduplicate findings that overlap across phases.

### 4.2 Compute Risk Score

**Per-finding risk score:**
```
risk = severity_weight x confidence / 100
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

### 4.3 Determine Verdict

| Verdict | Criteria |
|---------|----------|
| **APPROVE** | Risk 0-25, no Critical/High findings |
| **APPROVE WITH CHANGES** | Risk 26-50, no Critical findings, addressable issues |
| **REVISE** | Risk 51-75, Critical findings or multiple High |
| **REJECT** | Risk 76+, fundamental approach issues |

### 4.4 Generate Report

```markdown
## Plan Review: [Plan Name]

**Verdict**: APPROVE | APPROVE WITH CHANGES | REVISE | REJECT
**Risk Score**: X/100 | **Rollback**: Safe/With-Migration/Difficult/Irreversible | **Debt**: Reducing/Neutral/Introducing

---

### Risk Dashboard

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Grounding (codebase validation) | | | | |
| Completeness & Gaps | | | | |
| Risk & Feasibility | | | | |
| **Total** | | | | |

---

### Critical Findings (Must Address)

| # | Finding | Category | Confidence | Suggested Fix |
|---|---------|----------|------------|---------------|

### High-Priority Findings

| # | Finding | Category | Confidence | Suggested Fix |
|---|---------|----------|------------|---------------|

<details>
<summary>Medium/Low Findings (N items)</summary>

| # | Finding | Category | Severity | Confidence |
|---|---------|----------|----------|------------|

</details>

---

### Breaking Changes

| # | Change | Migration Path | Risk |
|---|--------|----------------|------|

### Scope Assessment

[Over-scoped / Under-scoped / Appropriate — with justification]

### Task Structure Assessment

[Task sizing, dependency correctness, parallelization opportunities, execution order safety]

---

### Questions for Clarification

1. [Specific question about ambiguous requirement]
2. [Question about intended behavior in edge case]

### What's Good

- [Strengths of the plan worth preserving]
- [Good decisions]

### Recommended Plan Modifications

1. [Specific modification with rationale]
2. [Additional step to add]
3. [Edge case handling to include]
```

### 4.5 Present and Ask Questions

Present the full report. If there are clarifying questions, **wait for answers** before suggesting plan updates.

---

## Phase 5: Suggest Updates & Handoff

### 5.1 Suggest Updates

Based on user answers and findings, propose specific edits:

- New tasks or steps to add
- Existing steps to modify
- Edge case handling to include
- Tests to add
- Breaking change mitigations

**ASK USER**: "Would you like me to apply these updates to the plan file?"

If yes, edit the plan file directly.

### 5.2 Execution Handoff

After updates are applied (or if no updates needed):

**ASK USER**: "Plan review complete. Ready to execute?"

If yes, break the plan into a prioritized task graph with dependencies and execute using Claude Tasks and Team Agents.

---

## Team Teardown

After the report is generated:

```
# After all agents confirmed shutdown
TeamDelete()
```

## Error Recovery

If a teammate crashes mid-phase:
1. Log the failure — remaining agents still contribute findings
2. Continue with next phase (partial results are still valuable)
3. Note the gap in the summary report
4. Adjust risk score confidence downward for the affected category

## Options

- `/review-plan <path>` — Review a plan file
- `/review-plan` — Paste or describe a plan to review
