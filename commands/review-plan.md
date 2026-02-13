---
description: Review an implementation plan for gaps, edge cases, and ambiguities
argument-hint: Path to plan file or paste plan inline
---

## Integration

Related: **`orchestration`** skill (`workflows/write-plan.md` creates plans, `workflows/orchestrate.md` builds task graphs), **`/feature-dev`** (guided development)

## Phase 1: Understand the Plan

### 1.1 Load the Plan

If a file path is provided, read it. Otherwise, ask the user to provide or paste the plan.

### 1.2 Understand the Codebase

Launch agents via Task tool (`subagent_type: "Explore"`) to understand the areas the plan touches:

> "Explore the codebase areas relevant to this plan: [summary of plan scope]. Map existing patterns, abstractions, integration points, and constraints. List 5-10 key files."

Read files identified by agents.

### 1.3 Summarize Understanding

Restate:
- What the plan aims to accomplish
- The proposed approach and key decisions
- Scope boundaries (what's in, what's out)

---

## Phase 2: Gap Analysis

Evaluate the plan against each category. For each finding, note severity (Critical/High/Medium/Low) and specific location in the plan.

### 2.1 Missing Requirements

- Features mentioned but not specified
- Implied behavior with no explicit handling
- Missing acceptance criteria
- Unclear success/failure definitions

### 2.2 Edge Cases

- Empty/null/undefined inputs
- Boundary values (0, 1, max, overflow)
- Concurrent access or race conditions
- Network failures, timeouts, partial failures
- Malformed or unexpected data formats
- Permission and authorization gaps
- State transitions that can fail mid-way

### 2.3 Error Handling

- Unhappy paths not addressed
- Missing rollback or cleanup on failure
- Silent failures (errors swallowed without logging)
- User-facing error messages not specified
- Retry logic for transient failures

### 2.4 Integration Points

- API contracts not fully specified (request/response shapes, error codes)
- Database schema changes without migration strategy
- Third-party service dependencies not accounted for
- Breaking changes to existing consumers
- Missing backwards compatibility considerations

### 2.5 Security

- Input validation gaps
- Authentication/authorization not specified
- Data exposure risks (logging PII, leaking internals)
- Injection vectors (SQL, XSS, command injection)

### 2.6 Performance

- N+1 query patterns
- Missing pagination or limits on unbounded lists
- Large payloads without streaming
- Missing caching where beneficial
- Operations that don't scale with data growth

### 2.7 Testing

- Missing test strategy for critical paths
- Edge cases identified above without corresponding tests
- Integration test gaps
- Missing negative tests (invalid input, unauthorized access)

### 2.8 Operational

- Missing logging or observability
- No monitoring or alerting plan
- Missing deployment/rollback strategy
- Feature flag or gradual rollout not considered

---

## Phase 3: Consistency & Dependency Check

### 3.1 Codebase Consistency
- Does the plan contradict existing codebase patterns?
- Are there naming inconsistencies?
- Are file paths accurate (verify against actual codebase)?
- Does the plan follow project conventions from CLAUDE.md?

### 3.2 Task Dependencies & Prioritization

**Every plan must be executable as a prioritized task graph.** Verify:

- **Explicit dependencies**: Each task clearly states what it depends on (or is explicitly independent)
- **Correct ordering**: Schema/types before business logic, infrastructure before features, tests alongside implementation
- **Parallelizable work identified**: Tasks that touch different files with no shared state should be grouped into parallel waves
- **No hidden dependencies**: Check for implicit ordering — e.g., Task 5 modifies a file that Task 3 creates, but no dependency is stated
- **Granularity**: Tasks are bite-sized (2-5 minutes each) — flag tasks that are too large and suggest splitting
- **Wave structure**: Tasks should be organizable into execution waves where each wave's tasks can run in parallel

**If the plan lacks explicit dependency information**, flag this as a **Critical Gap** and suggest adding a dependency graph section:

```markdown
## Task Dependencies
Task 1: [name] — no dependencies (Wave 1)
Task 2: [name] — no dependencies (Wave 1)
Task 3: [name] — blocked by Task 1 (Wave 2)
Task 4: [name] — blocked by Tasks 1, 2 (Wave 2)
Task 5: Integration — blocked by all (Wave 3)
```

---

## Phase 4: Present Findings

### 4.1 Report

```markdown
## Plan Review: [Plan Name]

### Critical Gaps (Must Address)
| # | Gap | Location in Plan | Impact | Suggested Fix |
|---|-----|------------------|--------|---------------|

### Edge Cases Missing
| # | Scenario | Affected Component | Suggested Handling |
|---|----------|--------------------|--------------------|

### Questions for Clarification
1. [Specific question about ambiguous requirement]
2. [Question about intended behavior in edge case]
3. [Question about scope boundary]

### Suggested Improvements
- [Improvement with rationale]

### What's Good
- [Strengths of the plan worth preserving]
```

### 4.2 Ask Questions

Present all clarifying questions to the user. **Wait for answers** before suggesting plan updates.

---

## Phase 5: Suggest Updates

Based on user answers, propose specific edits to the plan:

- New tasks or steps to add
- Existing steps to modify
- Edge case handling to include
- Tests to add

**ASK USER**: "Would you like me to apply these updates to the plan file?"

If yes, edit the plan file directly.

## Phase 6: Execution Handoff

After updates are applied (or if no updates needed):

**ASK USER**: "Plan review complete. Ready to execute?"

If yes, proceed to the orchestration skill's `workflows/orchestrate.md` to break the plan into a prioritized task graph with dependencies and execute using Claude Tasks and Team Agents.

## Options

- `/review-plan <path>` - Review a plan file
- `/review-plan` - Paste or describe a plan to review
