---
description: Peer review code changes using OpenAI Codex agents for a second AI opinion
---

Invoke Codex agents to peer review code changes independently from Claude.

## Prerequisites

Requires `codex-agent` CLI with tmux and Bun installed. Run `codex-agent health` to verify.

## Integration

Complements: **`/audit-code`** (Claude-based), **`/fix-pr-comments`** (automated tool responses)

## Phase 1: Determine Review Scope

Detect the base branch dynamically:
```bash
BASE_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo "main")
```

Resolve scope from `$ARGUMENTS` into three variables: `INTENT`, `FILES`, `DIFF_SUMMARY`. All later phases use these — never raw git commands against a hard-coded branch.

### Mode A: PR number

**If `$ARGUMENTS` matches `^[0-9]+$`:**

```bash
INTENT=$(gh pr view $ARGUMENTS --json title,body --jq '"PR #\(.number): \(.title)\n\(.body)"')
FILES=$(gh pr diff $ARGUMENTS --name-only | tr '\n' ',')
DIFF_SUMMARY=$(gh pr diff $ARGUMENTS --stat | tail -1)
```

### Mode B: Specific files

**If `$ARGUMENTS` contains file paths or globs:**

```bash
FILES="$ARGUMENTS"
INTENT=$(git log -5 --oneline -- $FILES)
DIFF_SUMMARY="Manual file selection: $FILES"
```

### Mode C: Branch diff (default)

**If no arguments provided:**

```bash
INTENT=$(git log $BASE_BRANCH..HEAD --oneline)
FILES=$(git diff $BASE_BRANCH...HEAD --name-only | tr '\n' ',')
DIFF_SUMMARY=$(git diff $BASE_BRANCH...HEAD --stat | tail -1)
```

**If branch diff is empty**, fall back to staged + unstaged:
```bash
FILES=$(git diff --name-only; git diff --cached --name-only | sort -u | tr '\n' ',')
DIFF_SUMMARY=$(git diff --stat; git diff --cached --stat | tail -1)
INTENT="Uncommitted changes"
```

**If still empty:** "No changes to review." — stop.

**CHECKPOINT**: `INTENT`, `FILES`, and `DIFF_SUMMARY` are resolved. All modes converge here.

---

## Phase 2: Build Diff Summary

Condense `DIFF_SUMMARY` into a readable description of what changed (files, line counts, nature of changes). Keep under 500 chars to fit in the agent prompt.

---

## Phase 3: Spawn Codex Review Agents

Launch 2 parallel Codex agents in read-only mode. Replace `{INTENT}`, `{DIFF_SUMMARY}`, and `{FILES}` with resolved values.

### 3.1 Agent 1: Correctness & Logic Review

```bash
codex-agent start "PEER REVIEW: Correctness & Logic

CHANGE INTENT: {INTENT}
DIFF SUMMARY: {DIFF_SUMMARY}

Review the changed files for bugs and logic errors. Focus on:
- Logic errors and broken assumptions
- Edge cases and off-by-one errors
- Null/undefined handling gaps
- Race conditions and concurrency issues
- Missing error handling
- Broken contracts (function signatures, return types)

For each issue, output this format:
  ISSUE: [short title]
  FILE: [path:line]
  CONFIDENCE: [0-100]
  SEVERITY: [Critical/High/Medium/Low]
  DESCRIPTION: [what's wrong]
  IMPACT: [what breaks]
  FIX: [specific code change]

Only report issues with confidence >= 80. Prioritize Critical/High over Medium/Low. Skip style nits." --map -s read-only -r high -f "{FILES}"
```

### 3.2 Agent 2: Architecture & Quality Review

```bash
codex-agent start "PEER REVIEW: Architecture & Quality

CHANGE INTENT: {INTENT}
DIFF SUMMARY: {DIFF_SUMMARY}

Review the changed files for design and quality issues. Focus on:
- API design problems (leaky abstractions, inconsistent interfaces)
- Security vulnerabilities (injection, auth gaps, data exposure)
- Performance concerns (N+1 queries, unnecessary allocations, blocking calls)
- Missing or inadequate tests for new/changed behavior
- Violations of existing project conventions and patterns
- Naming inconsistencies with surrounding code

For each issue, output this format:
  ISSUE: [short title]
  FILE: [path:line]
  CONFIDENCE: [0-100]
  SEVERITY: [Critical/High/Medium/Low]
  DESCRIPTION: [what's wrong]
  WHY IT MATTERS: [consequence if not fixed]
  SUGGESTION: [specific improvement]

Only report issues with confidence >= 80. Prioritize Critical/High over Medium/Low. Skip style nits." --map -s read-only -r high -f "{FILES}"
```

Note the job IDs from both commands.

---

## Phase 4: Monitor and Capture

Track agent progress. Typical review time: 10-20 minutes.

```bash
codex-agent jobs
```

For each agent, track:
- **Status**: running / success / failed / partial
- **Duration**: flag if >30 min

**If an agent appears stuck (>30 min):**
```bash
codex-agent capture <jobId>
codex-agent send <jobId> "Focus on the changed files only. Summarize your findings in the requested format."
```

**If an agent fails:** Note the failure reason. Do not respawn — synthesize from the remaining agent's output.

**Once both complete**, capture full results:
```bash
codex-agent capture <jobId1>
codex-agent capture <jobId2>
```

**CHECKPOINT**: Both agents completed (or one failed with reason noted).

---

## Phase 5: Synthesize Findings

Merge findings from both Codex agents:

### 5.1 Separate Signal from Noise

**Signal (keep):**
- Issues with confidence >= 80 that identify real bugs or risks
- Issues flagged by both agents (cross-validated)
- Issues consistent with the change intent and codebase patterns

**Noise (discard):**
- Issues based on misunderstood context (agent didn't understand the codebase)
- Over-engineered suggestions that add complexity without clear benefit
- Style preferences that contradict project conventions
- Issues about unchanged code (out of scope for this review)

### 5.2 Categorize Signal by Severity

- **Critical**: Security vulnerabilities, data loss risks, breaking bugs
- **High**: Logic errors, missing error handling, race conditions
- **Medium**: Architecture concerns, performance issues, missing tests
- **Low**: Naming inconsistencies, minor improvements

---

## Phase 6: Report

### 6.1 Determine Verdict

Based on synthesized findings:

| Verdict | Criteria |
|---------|----------|
| **PASS** | No Critical/High issues, at most minor Medium/Low |
| **PASS WITH CONCERNS** | No Critical, some High or multiple Medium worth addressing |
| **FAIL** | Any Critical issues, or multiple High issues that compound |

### 6.2 Present Report

```markdown
## Codex Peer Review Report

### Verdict: [PASS / PASS WITH CONCERNS / FAIL]

[1-2 sentence summary of overall code quality and change safety]

### Summary
- Files reviewed: [count]
- Signal: [count] issues (Critical: X, High: X, Medium: X, Low: X)
- Noise discarded: [count]
- Cross-validated (flagged by both agents): [count]

### Critical / High Issues
| # | File | Issue | Agent | Fix |
|---|------|-------|-------|-----|

### Medium / Low Issues
| # | File | Issue | Agent | Fix |
|---|------|-------|-------|-----|

### Cross-Validated
Issues flagged by both agents (highest confidence):
- [issue descriptions]

### Discarded (Noise)
- [issue] — [reason: misunderstood context / out of scope / contradicts conventions]

### Clean Areas
Areas both agents found no issues with:
- [areas]
```

### 6.3 Recommended Action

Based on the verdict:

- **PASS**: "Codex peer review passed. No blocking issues found."
- **PASS WITH CONCERNS**: "Codex review found [N] issues worth addressing before merge."
  **ASK USER**: "Want me to fix the High/Medium issues?"
- **FAIL**: "Codex review found Critical issues that should be fixed before merge."
  **ASK USER**: "Want me to fix the Critical/High issues now?"

---

## Usage Examples

```
/codex-review                    # Review current branch vs base
/codex-review 42                 # Review PR #42
/codex-review src/auth/**/*.ts   # Review specific files
```
