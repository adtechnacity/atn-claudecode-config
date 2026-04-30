---
description: Monitor a PR perpetually — fix bot review comments and CI failures (lint/tests/build), push, repeat until checks are green and no unprocessed comments remain
argument-hint: Optional PR number or URL
---

## Overview

Watches a PR continuously and drives it to a green, comment-clean fixed point. Each iteration:

1. Poll CI/Actions status and bot review comments.
2. If checks are still running, wait and re-poll.
3. If new bot comments OR failed checks (lint, tests, build, etc.) are present, investigate, fix, commit, push.
4. After push, CI re-runs and bots re-review — go back to step 1.
5. Exit only when **every** required check has settled to a non-failure conclusion **and** no unprocessed bot comments remain.

Run any time after opening a PR — even before bots have reviewed. The command waits for the first signals.

Mode: fully autonomous. No per-iteration approval. Stops only at the fixed point or on a stagnation guard (see Phase 6).

## Integration

Related: **`/pr`** (creates PRs), **`/audit-code`** (proactive code quality), **`/commit`** (commit fixes)

Per `CLAUDE.md`: actual fixing is delegated to subagents (e.g. `feature-dev:code-reviewer` for triage, `refactoring-expert` for mechanical changes, `security-sentinel` for security findings, `coderabbit:code-reviewer` for CodeRabbit-specific synthesis). The command orchestrates; subagents do the code work.

---

## Phase 0: Resolve PR and seed state

### 0.1 Resolve the PR

If a PR number/URL is provided, use it. Otherwise detect from current branch:

```bash
gh pr view --json number,title,headRefName,headRefOid,url,baseRefName
```

If no PR exists for the current branch, stop and inform the user.

Capture: `owner`, `repo`, `pr_number`, `head_sha`, `head_branch`.

### 0.2 In-memory state

Track across iterations:

- `processed_comment_ids`: set of bot comment IDs already addressed (fixed or marked false-positive)
- `processed_check_signatures`: set of `{check_name}:{conclusion}:{first_failed_step}` we've already attempted to fix
- `last_pushed_sha`: most recent SHA the loop pushed
- `iteration`: counter, starts at 1
- `consecutive_no_progress`: counter, increments when an iteration produces no new fixes despite seeing the same failure/comment

---

## Phase 1: Poll CI/Actions

```bash
gh pr checks <pr_number> --json name,status,conclusion,workflow,link,startedAt,completedAt
gh api repos/{owner}/{repo}/commits/<head_sha>/check-runs --paginate
```

Bucket each check:

| Bucket | Status / Conclusion |
|---|---|
| **Running** | status ∈ {QUEUED, IN_PROGRESS, PENDING, WAITING} |
| **Failed** | conclusion ∈ {FAILURE, TIMED_OUT, CANCELLED, ACTION_REQUIRED, STARTUP_FAILURE} |
| **Passed** | conclusion = SUCCESS |
| **Neutral** | conclusion ∈ {NEUTRAL, SKIPPED, STALE} — treated as non-blocking |

If any check is **Running**, sleep ~30s and re-poll. Surface a one-line status: `iter N · checks: 3 running, 2 passed, 0 failed · comments: 0 new`. Use the `Monitor` tool with an until-loop to wait efficiently when many checks are pending.

---

## Phase 2: Poll bot review comments

```bash
gh api repos/{owner}/{repo}/pulls/<pr_number>/comments --paginate
gh api repos/{owner}/{repo}/issues/<pr_number>/comments --paginate
gh api repos/{owner}/{repo}/pulls/<pr_number>/reviews --paginate
```

### 2.1 Recognized bot authors

| Tool | Author pattern |
|---|---|
| CodeRabbit | `coderabbitai[bot]`, `coderabbit-*` |
| CodeScene | `codescene[bot]`, `codescene-*` |
| SonarCloud | `sonarcloud[bot]`, `sonarqubecloud[bot]` |
| Codacy | `codacy[bot]`, `codacy-production[bot]` |
| DeepSource | `deepsource-io[bot]`, `deepsource-autofix[bot]` |
| Snyk | `snyk-bot`, `snyk[bot]` |
| Dependabot | `dependabot[bot]` |
| GitHub Actions | `github-actions[bot]` |
| Codex | `chatgpt-codex-connector[bot]`, `codex[bot]`, `openai-codex[bot]` |
| Generic | any author ending in `[bot]` with file/line references or code suggestions |

### 2.2 Filter to actionable

For each bot comment, **skip** if:

- ID is in `processed_comment_ids`
- It is a top-level summary/walkthrough/overview (no inline file:line and no actionable suggestion)
- It is marked resolved/outdated by GitHub
- Its `commit_id` predates `head_sha` AND a later commit already addresses the line

Otherwise extract: file path, line range, severity, category, description, suggested diff (if any). Group by file.

---

## Phase 3: Decide what this iteration must address

Build the **work set** for this iteration:

1. **New bot comments** from Phase 2.2 not in `processed_comment_ids`.
2. **Failed checks** from Phase 1 whose signature isn't in `processed_check_signatures`.

If the work set is empty AND no checks are running AND there are no Failed checks → go to **Phase 7 (terminate)**.

If the work set is empty BUT some checks are still running → loop back to Phase 1.

Otherwise continue.

---

## Phase 4: Fix the work set

Delegate to subagents. Run independent fixes in parallel by spawning multiple `Agent` calls in one message.

### 4.1 Bot comments

For each file with comments, spawn a subagent (`feature-dev:code-reviewer` for triage, `refactoring-expert` for mechanical edits, `security-sentinel` for security findings). Brief it with: file path, exact comment text, suggested diff if present, and the rule "fix only what's flagged; do not refactor surrounding code."

Validation per fix:

- Apply the minimal change.
- If a CodeRabbit suggestion block is present and correct, apply it verbatim.
- If the comment is a false positive after investigation, do not change code; record the comment ID in `processed_comment_ids` with reason. Surface suggested reply text in the final report (do NOT post replies automatically).

### 4.2 Failed CI checks

For each failed check, fetch logs and identify the failure:

```bash
gh run view <run_id> --log-failed
gh api repos/{owner}/{repo}/check-runs/<check_run_id>
```

Map common failures:

| Failure | Action |
|---|---|
| Lint (eslint, biome, prettier, rubocop, ruff) | Run the formatter/linter locally; fix remaining issues by hand |
| Type check (tsc, mypy, pyright, sorbet) | Read the error, fix types in the offending file |
| Tests (jest, vitest, pytest, rspec, go test) | Reproduce locally if possible; fix the code or the test if the test is wrong |
| Build (vite, next, webpack, cargo, go build) | Read the build error, fix imports/syntax/config |
| Security scans (Snyk, Dependabot, CodeQL) | Patch the vulnerable code or bump the dep; if not fixable in this PR, record signature in `processed_check_signatures` and surface in final report |
| Required reviewers / merge queue | Cannot fix — record signature and surface |

Record `{check_name}:{conclusion}:{first_failed_step}` in `processed_check_signatures` after attempting a fix, so the same exact failure isn't re-attempted next iteration.

### 4.3 Local validation before push

After fixes are applied, run the equivalent local checks (typecheck, lint, the failing tests) so we don't push a broken state and burn another CI cycle.

---

## Phase 5: Commit and push

If any files changed:

```bash
git add -A
git diff --cached --stat
git commit -m "fix: address PR review feedback (iter <N>)"
git push
```

Update `head_sha` and `last_pushed_sha` to the new commit. Add all addressed comment IDs to `processed_comment_ids`. Increment `iteration`.

If **no files changed** despite a non-empty work set (everything was a false positive or unfixable):

- Add the comment IDs / check signatures to their processed sets so we don't re-evaluate them next iteration.
- Increment `consecutive_no_progress`.
- Do not push. Loop back to Phase 1.

If files **did** change, reset `consecutive_no_progress` to 0.

---

## Phase 6: Stagnation guard

Before looping back, check loop-bomb conditions. Exit and ask the user if any hold:

- `consecutive_no_progress >= 3` (three iterations in a row produced no fixes)
- `iteration > 15` (sanity ceiling)
- Same check has now failed 3+ times after 3+ separate fix attempts (the fix isn't working)
- A bot has posted ≥3 new comments on a line we already touched in this run (likely disagreement loop)

When exiting via stagnation, surface the state and ASK USER what to do (continue, abandon specific items, hand off).

Otherwise loop back to **Phase 1**.

---

## Phase 7: Terminate (fixed point reached)

Conditions:

- Zero checks in Running bucket
- Zero checks in Failed bucket (excluding signatures the user accepted as un-fixable)
- Zero unprocessed bot comments

Final report:

```markdown
## PR Monitor Report: #<pr_number>

**Iterations**: N
**Final head**: <sha>

### Comments addressed
| Iter | Tool | File:Line | Issue | Resolution |
|------|------|-----------|-------|------------|

### CI failures fixed
| Iter | Check | Failure | Fix |
|------|-------|---------|-----|

### False positives / un-fixable (surfaced for you)
| Tool/Check | File:Line | Reason | Suggested reply |
|------------|-----------|--------|-----------------|

### Final CI status
| Check | Conclusion |
|-------|------------|

All required checks: green. No unprocessed bot comments.
```

---

## Options

- `/fix-pr-comments` — monitor current branch's PR
- `/fix-pr-comments 123` — monitor PR #123
- `/fix-pr-comments https://github.com/org/repo/pull/123` — monitor by URL

## Notes for the agent running this

- Use parallel `Agent` calls when fixing independent files in one iteration.
- When polling CI for long stretches, prefer `Monitor` with an until-loop over chained sleeps so you stay within cache windows and get notified on completion.
- Never `git push --force` here. Never skip hooks. If a hook fails, fix the underlying issue and create a new commit.
- Never post replies to bot comments automatically — surface suggested replies in the final report only.
- Stagnation guard is a hard backstop, not a target. The expected exit is Phase 7.
