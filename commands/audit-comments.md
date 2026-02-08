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

## Phase 1: Find Low-Value Comments

Launch via Task tool (`subagent_type: "general-purpose"`):
> "Review comment quality with confidence scoring (0-100, report >= 80). Flag: redundant (restates code), outdated (doesn't match behavior), commented-out code, noise (dividers, obvious headers). Note file:line for each."

## Phase 2: Find Missing Comments

Launch via Task tool (`subagent_type: "Explore"`):
> "Identify complex code lacking explanation: algorithms, business logic, API integrations, workarounds, undocumented public exports. Trace through the code to understand what each complex section does. Note file:line for each."

## Phase 3: Apply Changes

For findings with >=80 confidence:

**Remove:** Redundant, noise, commented-out code, outdated (or update)

**Add:** Algorithm explanations, business logic context, key public API docs

## Phase 4: Verification

Run type checker and tests.

### Summary Report
- Comments removed (locations)
- Comments added (locations)
- Commented-out code deleted
- Files modified

## Guidelines

- When uncertain about removal, keep
- When uncertain about adding, skip
- Prefer refactoring over explanatory comments
- Normalize comment format to match codebase style
- For bulk commented-out code, use `/cleanup`
