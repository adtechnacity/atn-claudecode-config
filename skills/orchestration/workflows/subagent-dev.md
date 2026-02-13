# Subagent-Driven Development

Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance first, then code quality.

**Core principle:** Fresh subagent per task + two-stage review = high quality, fast iteration.

## When to Use

- Have an implementation plan with mostly independent tasks
- Want to stay in the current session (vs `workflows/execute.md` for parallel sessions)
- Tasks can be implemented one at a time without tight coupling

## The Process

1. **Read plan** — Extract all tasks with full text
2. **Build task graph** — Create all tasks via TaskCreate with subject, description, and activeForm. Set dependencies via TaskUpdate with `addBlockedBy`/`addBlocks` (schema/types before logic, infrastructure before features, TDD pairs as single units, integration tests last). Present the prioritized task graph to the user for approval.
3. **Per task** (in dependency order):
   - Mark as `in_progress` via TaskUpdate
   - Dispatch implementer subagent with full task context
   - Answer any clarifying questions before work begins
   - Implementer implements, tests, commits, and self-reviews
   - Dispatch spec compliance reviewer
   - If issues found: implementer fixes, reviewer re-reviews
   - Dispatch code quality reviewer
   - If issues found: implementer fixes, reviewer re-reviews
   - Mark task `completed` via TaskUpdate
   - Check TaskList for newly unblocked tasks
4. **After all tasks** — Dispatch final code reviewer for entire implementation
5. **Complete** — Follow `workflows/finish-branch.md`

## Implementer Prompt Template

Dispatch via Task tool (`subagent_type: "general-purpose"`):

> You are implementing Task N: [task name]
>
> **Task Description:** [FULL TEXT from plan — don't make subagent read plan file]
>
> **Context:** [Where this fits, dependencies, architectural context]
>
> **Before you begin:** If you have questions about requirements, approach, or dependencies — ask them now.
>
> **Your job:** Implement exactly what the task specifies. Write tests (TDD if specified). Verify it works. Commit. Self-review for completeness, quality, and YAGNI. Fix any issues before reporting.
>
> **Report:** What you implemented, test results, files changed, self-review findings, concerns.

## Spec Compliance Reviewer Template

Dispatch via Task tool (`subagent_type: "general-purpose"`):

> You are reviewing whether an implementation matches its specification.
>
> **What was requested:** [FULL TEXT of task requirements]
>
> **What implementer claims they built:** [From implementer's report]
>
> **Do NOT trust the report.** Read the actual code. Verify:
> - **Missing requirements** — Did they implement everything requested?
> - **Extra work** — Did they build things not requested?
> - **Misunderstandings** — Did they solve the wrong problem?
>
> Report: Spec compliant (all requirements met) or Issues found (list what's missing/extra with file:line references).

## Code Quality Reviewer Template

Dispatch via Task tool (`subagent_type: "general-purpose"`):

> Review the implementation for code quality. Focus on: clean code, test coverage, maintainability, naming, duplication, complexity. Only report issues with confidence >= 80.
>
> **What was implemented:** [From implementer's report]
> **Changes:** commits between [base SHA] and [current SHA]

## Red Flags

**Never:**
- Skip reviews (spec compliance OR code quality)
- Proceed with unfixed issues
- Dispatch multiple implementers in parallel (conflicts)
- Make subagent read plan file (provide full text instead)
- Start code quality review before spec compliance passes
- Accept "close enough" on spec compliance
- Skip review re-loops (reviewer found issues = implementer fixes = review again)

**If subagent asks questions:** Answer clearly and completely before letting them proceed.

**If reviewer finds issues:** Implementer fixes, reviewer re-reviews. Repeat until approved.

**If subagent fails task:** Dispatch fix subagent with specific instructions. Don't fix manually (context pollution).

## Integration

**Calls:** `workflows/finish-branch.md` — Complete development after all tasks

**Subagents follow:** `test-driven-development` skill for each task
