# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the orchestration skill to implement this plan."

## The Process

### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Proceed to task graph creation

### Step 2: Build Task Graph

Create a structured task graph from the plan using Claude Tasks:

1. **Create all tasks** via TaskCreate with:
   - **subject**: Imperative form (e.g., "Implement user auth middleware")
   - **description**: Full task details from the plan — files, steps, acceptance criteria, test requirements
   - **activeForm**: Present continuous (e.g., "Implementing user auth middleware")

2. **Set dependencies** via TaskUpdate with `addBlockedBy`/`addBlocks`:
   - Schema/types before business logic
   - Infrastructure before features
   - TDD pairs as single units
   - Integration tests after components

3. **Identify waves** — group tasks by dependency depth:
   - Wave 1: Tasks with no dependencies (can run in parallel)
   - Wave 2: Tasks blocked only by Wave 1
   - Wave N: Tasks blocked only by completed waves

4. **Present graph to user** and confirm execution order

### Step 3: Execute by Waves

For each wave, execute all unblocked tasks:

**If 2+ unblocked tasks are independent (different files, no shared state):**
- Dispatch parallel agents using `workflows/parallel-dispatch.md`

**If only 1 task or tasks share files:**
- Execute sequentially

For each task:
1. Mark as `in_progress` via TaskUpdate
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as `completed` via TaskUpdate
5. Check TaskList for newly unblocked tasks

### Step 4: Report Between Waves
After each wave completes:
- Show what was implemented and test results
- Show which tasks are now unblocked
- Say: "Wave N complete. Ready for feedback."

### Step 5: Continue
Based on feedback:
- Apply changes if needed
- Execute next wave
- Repeat until all tasks complete

### Step 6: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the orchestration skill to finish this development branch."
- **REQUIRED:** Follow `workflows/finish-branch.md`
- Verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Calls:** `workflows/finish-branch.md` — Complete development after all tasks
