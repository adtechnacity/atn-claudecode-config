---
description: Audit code comments for relevance, remove unnecessary ones, add missing ones
---

Audit all code comments to ensure they add value. Remove redundant/outdated comments and add comments where complex logic needs explanation. This improves maintainability for both humans and AI assistants.

## Integration

This command is used by:
- **`/commit`** (Step 1) - Comment audit before committing
- **`/ship`** - Indirectly via `/commit` workflow

Related commands:
- **`/cleanup`** - Can also remove commented-out code blocks
- **`/review`** - May identify comment quality issues

Active hooks:
- **`auto-format-on-save.sh`** - Handles code formatting automatically after edits

## Comment Quality Principles

**Good comments explain WHY, not WHAT.** Code shows what it does; comments should explain non-obvious reasoning.

### Comments to Keep/Add
- **Why decisions**: Explain non-obvious choices or trade-offs
- **Complex algorithms**: High-level explanation of what algorithm does and why
- **Business logic**: Domain knowledge a developer wouldn't know from code
- **Edge cases**: Document subtle behavior that isn't self-evident
- **API integrations**: Explain external API quirks or requirements
- **Workarounds**: Explain why a hack exists and when it can be removed
- **TODOs with context**: Actionable items with enough detail to act on
- **Public API docs**: Doc comments for exported interfaces and functions

### Comments to Remove
- **Redundant**: Restates what code obviously does (`// increment counter`)
- **Outdated**: Doesn't match current code behavior
- **Commented-out code**: Dead code should be deleted, not commented (use `/cleanup`)
- **Noise**: Divider lines, obvious section headers, empty comments
- **Apologetic**: "Sorry this is hacky" - fix it or accept it

## Agent Integration

| Agent | Purpose |
|-------|---------|
| `feature-dev:code-reviewer` | Identify low-value comments |
| `feature-dev:code-explorer` | Identify complex code lacking explanation |

## Phase 1: Find Low-Value Comments

Launch `feature-dev:code-reviewer` with prompt:
> "Review comments in the source code for quality issues. Flag: redundant comments that restate code, outdated comments that don't match behavior, commented-out code blocks, noise comments. Note file:line for each."

## Phase 2: Find Missing Comments

Launch `feature-dev:code-explorer` with prompt:
> "Identify complex code that lacks explanation. Look for: algorithms without high-level explanation, non-obvious business logic, external API integrations without context, workarounds without justification, public exports without doc comments. Note file:line for each."

## Phase 3: Apply Changes

For agent findings with ≥80 confidence:

**Remove:**
- Redundant and noise comments
- Commented-out code blocks (or use `/cleanup` command)
- Outdated comments (or update if salvageable)

**Add:**
- Brief explanation for complex algorithms
- Context for business logic and API quirks
- Doc comments for key public interfaces

**Note:** The `auto-format-on-save.sh` hook will automatically format files after edits.

## Phase 4: Verification

Run the project's type checker and tests to ensure no regressions.

### Summary Report
- Comments removed (with locations)
- Comments added (with locations)
- Commented-out code deleted
- Files modified

## Guidelines

- When uncertain about removal, keep the comment
- When uncertain about adding, skip it - don't over-comment
- Prefer refactoring unclear code over adding explanatory comments
- **Normalize comment format**: Ensure consistent style across the project (e.g., sentence case, punctuation, spacing). Match the predominant pattern in the codebase.
- For large amounts of commented-out code, consider using `/cleanup` command instead
