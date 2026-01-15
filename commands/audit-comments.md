---
description: Audit code comments for relevance, remove unnecessary ones, add missing ones
---

Audit comments to ensure they add value. Remove redundant/outdated comments, add explanations for complex logic.

## Integration

Used by: **`/commit`** (Step 1), **`/ship`** (via `/commit`)

Related: **`/cleanup`** (commented-out code), **`/review`** (comment quality)

Hook: **`auto-format-on-save.sh`** handles formatting after edits

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

## Agent Integration

| Agent | Purpose |
|-------|---------|
| `feature-dev:code-reviewer` | Find low-value comments |
| `feature-dev:code-explorer` | Find complex code lacking explanation |

## Phase 1: Find Low-Value Comments

> "Review comment quality. Flag: redundant, outdated, commented-out code, noise. Note file:line."

## Phase 2: Find Missing Comments

> "Identify complex code lacking explanation: algorithms, business logic, API integrations, workarounds, undocumented public exports. Note file:line."

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
