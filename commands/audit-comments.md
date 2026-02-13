---
description: Audit code comments for relevance, remove unnecessary ones, add missing ones
---

Audit comments to ensure they add value. Remove redundant/outdated comments, add explanations for complex logic.

## Integration

Used by: **`/ship`** (via `/audit-all`)

Related: **`/cleanup`** (commented-out code), **`/audit-code`** (code quality)

Hook: **`format-and-lint.sh`** handles formatting after edits

## Comment Principles

**Good comments explain WHY, not WHAT.**

### Keep/Add
- Non-obvious decisions and trade-offs
- Algorithm explanations (high-level)
- Business logic/domain knowledge
- Edge case documentation
- External API quirks
- Workarounds (why and when removable)
- Actionable TODOs with context
- Public API doc comments

### Remove
- Redundant (restates obvious code)
- Outdated (doesn't match behavior)
- Commented-out code (use `/cleanup`)
- Noise (dividers, obvious headers)
- Apologetic ("sorry this is hacky")

## Mode Detection

Detect whether running standalone or inside `/audit-all`:

- **Standalone**: Run all 4 phases (find low-value, find missing, apply changes, verify)
- **Inside `/audit-all`**: Run only Phases 1-2 (analysis). Post findings via TaskCreate for the orchestrator. Skip Phases 3-4 (changes and verification are handled by the orchestrator's quality gates).

Check if a task list already exists with `audit-all` tasks to determine mode.

## Phase 1 + Phase 2: Parallel Analysis

Launch both agents in a single message (`run_in_background: true`):

### Phase 1: Find Low-Value Comments

Launch via Task tool (`subagent_type: "general-purpose"`, `run_in_background: true`):
> "Review comment quality with confidence scoring (0-100, report >= 80). Flag: redundant (restates code), outdated (doesn't match behavior), commented-out code, noise (dividers, obvious headers). Note file:line for each.
>
> Post each finding as a task via TaskCreate:
>   subject: '[Low-Value Comment] <brief description>'
>   description: Full details with file:line references and the comment text
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 1, audit: 'comments', files: ['path']}"

### Phase 2: Find Missing Comments

Launch via Task tool (`subagent_type: "Explore"`, `run_in_background: true`):
> "Identify complex code lacking explanation: algorithms, business logic, API integrations, workarounds, undocumented public exports. Trace through the code to understand what each complex section does. Note file:line for each.
>
> Post each finding as a task via TaskCreate:
>   subject: '[Missing Comment] <brief description>'
>   description: Full details with file:line references and suggested comment
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 2, audit: 'comments', files: ['path']}"

After both agents return, read all findings from TaskList.

## Phase 3: Apply Changes (standalone only)

Skip this phase when running inside `/audit-all`.

Consolidate findings from Phases 1-2. For findings with >= 80 confidence:

**Cross-phase conflict resolution**: If Phase 1 flags a comment for removal but Phase 2 identifies the same area as needing explanation → improve the comment instead of removing it.

**Remove:** Redundant, noise, commented-out code, outdated (or update)

**Add:** Algorithm explanations, business logic context, key public API docs

## Phase 4: Verification (standalone only)

Skip this phase when running inside `/audit-all`.

Run type checker and tests.

### Summary Report
- Comments removed (locations)
- Comments added (locations)
- Commented-out code deleted
- Files modified

## Error Recovery

If an agent crashes mid-phase:
1. The other parallel agent's findings are still valid — continue with partial results
2. Note the gap in the summary (e.g., "Phase 2 missing comments analysis incomplete")
3. Optionally re-dispatch the failed agent
4. Do not block on partial failure — partial results are valuable

## Guidelines

- When uncertain about removal, keep
- When uncertain about adding, skip
- Prefer refactoring over explanatory comments
- Normalize comment format to match codebase style
- For bulk commented-out code, use `/cleanup`
