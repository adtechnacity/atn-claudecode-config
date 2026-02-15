---
description: CodeRabbit-style multi-agent code review with inline findings and verdicts
argument-hint: PR number, file paths, or blank for branch diff
---

## Integration

Used by: **`/pr`** (runs automatically before PR creation)

Related: **`/audit-code`** (full codebase audit), **`/codex-review`** (Codex peer review), **`/fix-pr-comments`** (fix bot comments)

**Key distinction**: `/review-code` reviews **changes only** (diff-scoped, like CodeRabbit). `/audit-code` audits the **entire codebase**.

## Build System Detection

| Indicator | Type Check | Lint | Test | Build |
|-----------|------------|------|------|-------|
| `package.json` | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | `mypy .` | `ruff check .` | `pytest` | N/A |

Skip unavailable commands.

## Phase 1: Determine Review Scope

Detect the base branch dynamically:
```bash
BASE_BRANCH=$(git symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||' || echo "main")
```

Resolve scope from `$ARGUMENTS`:

### Mode A: PR number

**If `$ARGUMENTS` matches `^[0-9]+$`:**

```bash
PR_TITLE=$(gh pr view $ARGUMENTS --json title --jq '.title')
PR_BODY=$(gh pr view $ARGUMENTS --json body --jq '.body')
CHANGED_FILES=$(gh pr diff $ARGUMENTS --name-only)
DIFF=$(gh pr diff $ARGUMENTS)
DIFF_STAT=$(gh pr diff $ARGUMENTS --stat)
```

### Mode B: Specific files

**If `$ARGUMENTS` contains file paths or globs:**

```bash
CHANGED_FILES="$ARGUMENTS"
DIFF=$(git diff $BASE_BRANCH...HEAD -- $CHANGED_FILES)
DIFF_STAT=$(git diff $BASE_BRANCH...HEAD --stat -- $CHANGED_FILES)
```

### Mode C: Branch diff (default)

**If no arguments provided:**

```bash
CHANGED_FILES=$(git diff $BASE_BRANCH...HEAD --name-only)
DIFF=$(git diff $BASE_BRANCH...HEAD)
DIFF_STAT=$(git diff $BASE_BRANCH...HEAD --stat)
COMMIT_LOG=$(git log $BASE_BRANCH..HEAD --oneline)
```

**If branch diff is empty**, fall back to staged + unstaged:
```bash
CHANGED_FILES=$(git diff --name-only; git diff --cached --name-only | sort -u)
DIFF=$(git diff; git diff --cached)
DIFF_STAT=$(git diff --stat; git diff --cached --stat)
```

**If still empty:** "No changes to review." — stop.

### 1.2 Build Review Context

```markdown
## Review Context

**Branch**: [current branch]
**Base**: [base branch]
**Changed Files**: [count] files | [insertions]+ [deletions]-
**Commits**: [count] commits

### Changed Files
- [file path] ([+lines/-lines])

### Change Summary
[1-2 sentence summary derived from commit messages and diff]
```

---

## Team Setup

### Stale Cleanup

Check `~/.claude/teams/` for `review-code-*` directories and delete if found.

### Create Team

```
TeamCreate(team_name: "review-code-<YYYYMMDD-HHmmss>")
```

---

## Phase 2: Deep Codebase Context (2 Explore agents)

Spawn both explorers as teammates in a single message:

```
Task(subagent_type: "Explore", team_name: "review-code-<ts>", name: "change-validator", model: "opus",
  prompt: "You are a change validator for a code review.

[REVIEW CONTEXT — from Phase 1]
[FULL DIFF]

Your job: validate every change against the actual codebase.

1. **Pattern consistency**: Do the changes follow existing codebase patterns? Check naming conventions, file organization, abstraction layers, error handling patterns.
2. **CLAUDE.md conventions**: Check if changes follow project conventions from CLAUDE.md.
3. **Function signatures**: For modified functions, verify callers aren't broken by signature changes.
4. **Import correctness**: Verify new imports reference real modules with correct export names.
5. **Type consistency**: Check that new types/interfaces are consistent with existing type patterns.

Post each finding as a task via TaskCreate:
  subject: '[Validation] <brief description>'
  description: '**File**: `path`\n**Line**: LN\n**Issue**: ...\n**Expected**: ...'
  metadata: {type: 'finding', category: 'validation', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 2, files: ['path']}

Only report findings with confidence >= 75.
Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'validation'})")

Task(subagent_type: "Explore", team_name: "review-code-<ts>", name: "impact-tracer", model: "opus",
  prompt: "You are an impact tracer for a code review.

[REVIEW CONTEXT — from Phase 1]
[CHANGED FILES LIST]

Your job: trace the impact of every changed file.

1. **Direct consumers**: For each modified file, find all files that import from it.
2. **Transitive consumers**: For high-impact files (shared utils, types, API routes), trace one more level.
3. **Consumer Map**: Build a structured map:
   - file_modified → [direct_consumers] → [transitive_consumers]
4. **Blast radius**: For each modified file, count total downstream consumers. Flag files with 10+ consumers as high-blast-radius.
5. **Cross-boundary impacts**: Note if changes cross module/package boundaries.
6. **Untested consumers**: Flag consumers that might break but aren't covered by tests in this change.

Post the Consumer Map as a task:
  TaskCreate(subject: 'Consumer Map', description: '<full map>', metadata: {type: 'consumer-map', phase: 2})

For each high-blast-radius or cross-boundary finding:
  TaskCreate(subject: '[Impact] <brief description>', description: '...', metadata: {type: 'finding', category: 'impact', severity: 'High|Medium', confidence: <0-100>, phase: 2, files: ['path']})

Only report findings with confidence >= 75.
Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'impact'})")
```

### After Phase 2

1. Wait for both explorers to return.
2. Read all tasks from TaskList — collect findings and the Consumer Map.
3. Read key files posted by explorers.
4. Shutdown explorers:

```
SendMessage(type: "shutdown_request", recipient: "change-validator", content: "Validation complete")
SendMessage(type: "shutdown_request", recipient: "impact-tracer", content: "Tracing complete")
```

5. Build a **Phase 2 Summary** combining validation findings and Consumer Map.

---

## Phase 3–5: Wave 1 (3 agents in parallel)

Spawn all three agents as teammates in a single message. Each receives the Review Context, the diff, Phase 2 Summary, and Consumer Map.

### Phase 3: Correctness & Logic

```
Task(subagent_type: "general-purpose", team_name: "review-code-<ts>", name: "correctness-reviewer", model: "opus",
  prompt: "You are a correctness and logic reviewer for a code review.

[REVIEW CONTEXT]
[FULL DIFF]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Review the CHANGED CODE ONLY for bugs and logic errors:

1. **Logic errors**: Broken conditionals, wrong comparisons, inverted booleans, incorrect operator precedence
2. **Null/undefined handling**: Missing null checks, optional chaining gaps, unhandled nullable returns
3. **Edge cases**: Off-by-one errors, empty arrays/strings, boundary conditions, integer overflow
4. **Race conditions**: Concurrent state mutations, TOCTOU bugs, missing locks/semaphores
5. **Error handling**: Uncaught exceptions, swallowed errors, missing error propagation, incorrect error types
6. **Contract violations**: Functions that don't match their declared types, broken invariants, incorrect return values
7. **State management**: Stale state, mutation of shared state, missing state updates

For each finding, report with INLINE format — reference the specific diff hunk:
  TaskCreate(
    subject: '[Bug] <brief description>',
    description: '**File**: `path/to/file`\n**Line**: L42-L45\n**Diff hunk**:\n```\n<relevant code>\n```\n**Issue**: <what is wrong>\n**Impact**: <what breaks>\n**Fix**:\n```\n<suggested code change>\n```',
    metadata: {type: 'finding', category: 'correctness', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 3, files: ['path']})

Before starting, check TaskList for Phase 2 findings. Skip already-reported issues.
Only report findings with confidence >= 75.")
```

### Phase 4: Security & Data Safety

```
Task(subagent_type: "security-scanner", team_name: "review-code-<ts>", name: "security-reviewer", model: "opus",
  prompt: "You are a security reviewer for a code review.

[REVIEW CONTEXT]
[FULL DIFF]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Review the CHANGED CODE ONLY for security vulnerabilities:

1. **Injection**: SQL injection, XSS, command injection, path traversal, template injection
2. **Auth/AuthZ**: Missing authentication checks, broken authorization, privilege escalation
3. **Data exposure**: Sensitive data in logs, error messages, responses, URLs, or client-side code
4. **Input validation**: Missing validation at API boundaries, type coercion issues, regex DoS
5. **Cryptography**: Weak algorithms, hardcoded secrets, insecure random, missing encryption
6. **CORS/CSP**: Overly permissive policies, missing headers
7. **Rate limiting**: Unprotected endpoints, resource exhaustion vectors
8. **Data safety**: Missing transactions, concurrent write conflicts, idempotency gaps

For each finding, report with INLINE format:
  TaskCreate(
    subject: '[Security] <brief description>',
    description: '**File**: `path/to/file`\n**Line**: L42-L45\n**Diff hunk**:\n```\n<relevant code>\n```\n**Vulnerability**: <OWASP category or CWE>\n**Risk**: <what could be exploited>\n**Remediation**:\n```\n<suggested fix>\n```',
    metadata: {type: 'finding', category: 'security', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 4, files: ['path']})

Before starting, check TaskList for existing findings. Skip already-reported issues.
Only report findings with confidence >= 75.")
```

### Phase 5: Architecture & Quality

```
Task(subagent_type: "general-purpose", team_name: "review-code-<ts>", name: "architecture-reviewer", model: "opus",
  prompt: "You are an architecture and quality reviewer for a code review.

[REVIEW CONTEXT]
[FULL DIFF]
[PHASE 2 SUMMARY — validation findings + Consumer Map]

Review the CHANGED CODE ONLY for architecture and quality concerns:

1. **API design**: Leaky abstractions, inconsistent interfaces, unclear contracts
2. **Coupling**: Tight coupling introduced, circular dependency risks, module boundary violations
3. **Complexity**: Functions exceeding 50 lines, nesting beyond 3 levels, god objects/modules
4. **Anti-patterns**: Feature envy, shotgun surgery, premature abstraction, duplicate code
5. **Performance**: N+1 queries, unnecessary allocations, blocking calls, missing caching, O(n^2) algorithms
6. **Testing gaps**: New behavior without tests, modified behavior with stale tests, missing edge case coverage
7. **Breaking changes**: API signature changes, removed exports, schema changes without migration
8. **Naming & consistency**: Inconsistent naming with surrounding code, unclear variable/function names

For each finding, report with INLINE format:
  TaskCreate(
    subject: '[Quality] <brief description>',
    description: '**File**: `path/to/file`\n**Line**: L42-L45\n**Diff hunk**:\n```\n<relevant code>\n```\n**Issue**: <what is wrong>\n**Why it matters**: <consequence>\n**Suggestion**:\n```\n<improvement>\n```',
    metadata: {type: 'finding', category: 'architecture', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 5, files: ['path']})

Before starting, check TaskList for existing findings. Skip already-reported issues.
Only report findings with confidence >= 75.")
```

### After Wave 1

1. Wait for all three agents to return.
2. Read all new tasks from TaskList — collect Phase 3-5 findings.
3. Shutdown all agents:

```
SendMessage(type: "shutdown_request", recipient: "correctness-reviewer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "security-reviewer", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "architecture-reviewer", content: "Review complete")
```

---

## Phase 6: Synthesis, Scoring & Report (lead, no agents)

### 6.1 Aggregate Findings

Review all tasks from TaskList with `metadata.type: "finding"`. Deduplicate findings that overlap across phases (same file + same issue = keep higher-severity version).

### 6.2 Compute Risk Scores

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

**Overall Risk Score (0-100):**
1. Sum all per-finding risk scores
2. Normalize to 0-100 scale based on change scope (more files = higher tolerance)
3. Apply blast radius multiplier:
   - Small (5 or fewer consumers): x1.0
   - Medium (6-15 consumers): x1.1
   - Large (16-30 consumers): x1.25
   - Critical (30+ or cross-service): x1.5

### 6.3 Determine Verdict

| Verdict | Criteria |
|---------|----------|
| **APPROVE** | Risk 0-25, no Critical/High findings |
| **APPROVE WITH SUGGESTIONS** | Risk 26-50, no Critical, minor improvements possible |
| **REQUEST CHANGES** | Risk 51-75, Critical or multiple High findings need fixing |
| **REJECT** | Risk 76+, fundamental issues with the approach |

### 6.4 Generate Report

```markdown
## Code Review: [branch name or PR title]

**Verdict**: APPROVE | APPROVE WITH SUGGESTIONS | REQUEST CHANGES | REJECT
**Risk Score**: X/100 | **Blast Radius**: S/M/L/C | **Files**: N changed

---

### Summary

[2-3 sentence summary: what the changes do, overall quality assessment, key concerns if any]

### Risk Dashboard

| Category | Critical | High | Medium | Low |
|----------|----------|------|--------|-----|
| Validation & Patterns | | | | |
| Impact & Blast Radius | | | | |
| Correctness & Logic | | | | |
| Security & Data Safety | | | | |
| Architecture & Quality | | | | |
| **Total** | | | | |

---

### File-by-File Review

#### `path/to/file1.ts`

| # | Line | Severity | Finding | Suggested Fix |
|---|------|----------|---------|---------------|
| 1 | L42 | Critical | [description] | [fix] |
| 2 | L87 | Medium | [description] | [fix] |

#### `path/to/file2.ts`

| # | Line | Severity | Finding | Suggested Fix |
|---|------|----------|---------|---------------|

[Repeat for each file with findings]

---

### Breaking Changes

| # | Change | Type | Affected Consumers | Migration Needed |
|---|--------|------|--------------------|------------------|

### Blast Radius

[Consumer Map summary — which downstream files are most impacted]

---

<details>
<summary>Medium/Low Findings (N items)</summary>

| # | File | Line | Severity | Finding |
|---|------|------|----------|---------|

</details>

### What's Good

- [Positive aspects of the code changes]
- [Good patterns followed]
- [Well-handled edge cases]

### Recommended Changes

1. **[Must Fix]**: [specific change with rationale]
2. **[Should Fix]**: [specific change with rationale]
3. **[Consider]**: [optional improvement]
```

---

## Phase 7: Propose Fixes & Clarify

After generating the report, proactively address findings.

### 7.1 Clarification Questions

Review all findings for ambiguous intent — cases where the reviewer can't tell if the code is intentional or a bug. Group these and ask the user **once** using AskUserQuestion:

Example scenarios requiring clarification:
- A `// TODO` was added — is this intentional tech debt or forgotten work?
- A function's error handling changed — was the old behavior a bug or a feature?
- A new dependency was added when an existing utility could work — intentional choice?
- An edge case is unhandled — is the caller guaranteed to prevent it?

Skip this step if no ambiguities exist.

### 7.2 Propose Fixes

For all Critical and High findings, generate concrete fix proposals:

```markdown
### Proposed Fixes

#### Fix 1: [Finding title]
**File**: `path/to/file.ts` L42-L48
**Issue**: [brief description]

```diff
- <current code>
+ <proposed fix>
```

#### Fix 2: ...
```

For Medium findings, list them as optional improvements.

### 7.3 Apply Fixes

**ASK USER** (use AskUserQuestion):
- Header: "Fixes"
- Question: "Found [N] issues. How would you like to proceed?"
- Options:
  - **Fix all Critical & High** — Apply [N] fixes automatically
  - **Let me pick** — Review each fix individually
  - **Skip fixes** — Continue without fixing (not recommended if REQUEST CHANGES/REJECT)

Based on user choice:
- **Fix all**: Apply all Critical/High fixes, then re-run validation (type check, lint, test if available)
- **Let me pick**: Present each fix individually, apply approved ones, then re-run validation
- **Skip fixes**: Proceed without changes

### 7.4 Re-validate (if fixes applied)

After applying fixes:
1. Re-run type checker and linter (use Build System Detection table above)
2. Run tests if available
3. Update the verdict and risk score based on remaining findings
4. Show updated summary: "Fixed [N] issues. Verdict changed from REQUEST CHANGES → APPROVE WITH SUGGESTIONS."

---

## Team Teardown

After the report is generated, if any agents remain:

```
# After all confirm shutdown
TeamDelete()
```

## Error Recovery

If a teammate crashes mid-phase:
1. Log the failure — remaining agents still contribute findings
2. Continue with next phase (partial results are still valuable)
3. Optionally spawn a replacement agent on the same team
4. Note the gap in the summary report
5. Adjust risk score confidence downward for the affected category

## Options

- `/review-code` — Review current branch changes vs base
- `/review-code 42` — Review PR #42
- `/review-code src/auth/**/*.ts` — Review specific files
