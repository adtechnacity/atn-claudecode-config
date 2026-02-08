---
name: task-orchestration
description: Use after creating a plan to break it into Claude Tasks with dependencies, then orchestrate execution with parallel and sequential agents
---

# Task Orchestration

## Overview

Convert an implementation plan into a structured task graph using Claude's task system (TaskCreate, TaskUpdate, TaskList). Set dependencies, identify parallelizable work, and orchestrate execution using agent teams and parallel dispatch.

**Core principle:** Plans describe WHAT to build. This skill converts that into a dependency-aware execution graph that maximizes throughput by running independent tasks in parallel while respecting sequential constraints.

**Announce at start:** "I'm using the task-orchestration skill to break this plan into tasks and set up the execution graph."

## When to Use

- After `writing-plans` creates an implementation plan
- After `/review-plan` approves a plan
- When you have a multi-task plan and want structured execution tracking
- When tasks have dependencies that determine execution order

## Phase 1: Analyze the Plan

### 1.1 Load the Plan

Read the plan file. Extract every task with its:
- Name and description
- Files to create/modify
- Dependencies on other tasks (explicit or implicit)
- Estimated complexity (S/M/L)

### 1.2 Build the Dependency Graph

For each task, determine:
- **What it needs:** Which tasks must complete before this one can start?
- **What it enables:** Which tasks are blocked until this one completes?
- **Is it independent?** Can it run in parallel with other tasks?

Common dependency patterns:
- **Schema/types first** — data models before business logic
- **Infrastructure before features** — config, utils, shared code before consumers
- **Tests alongside implementation** — TDD pairs are one unit, not separate tasks
- **Integration after units** — integration tests after components exist

### 1.3 Identify Parallel Lanes

Group tasks into parallel execution lanes — sets of tasks that can run concurrently because they:
- Touch different files
- Don't share mutable state
- Have no dependency relationship

```
Lane A: [Task 1] → [Task 4] → [Task 7]
Lane B: [Task 2] → [Task 5]
Lane C: [Task 3] → [Task 6] → [Task 8]
         └── all lanes merge → [Task 9: Integration]
```

---

## Phase 2: Create Task Graph

### 2.1 Create All Tasks

Use TaskCreate for each task. Include:
- **subject**: Imperative form (`Implement user auth middleware`)
- **description**: Full task details from the plan — files, steps, acceptance criteria, test requirements. Subagents receiving these tasks do NOT have conversation history, so include ALL context needed.
- **activeForm**: Present continuous (`Implementing user auth middleware`)

### 2.2 Set Dependencies

Use TaskUpdate with `addBlockedBy` and `addBlocks` to wire the dependency graph:

```
TaskUpdate(taskId: "2", addBlockedBy: ["1"])   // Task 2 waits for Task 1
TaskUpdate(taskId: "5", addBlockedBy: ["2", "3"])  // Task 5 waits for both 2 and 3
```

### 2.3 Present the Graph

Show the user the execution plan:

```markdown
## Task Execution Graph

### Wave 1 (parallel — no dependencies)
- [ ] Task 1: [name] (S)
- [ ] Task 2: [name] (M)
- [ ] Task 3: [name] (S)

### Wave 2 (after Wave 1 completes)
- [ ] Task 4: [name] — blocked by Task 1
- [ ] Task 5: [name] — blocked by Tasks 2, 3

### Wave 3 (after Wave 2 completes)
- [ ] Task 6: [name] — blocked by Task 4

### Final (after all waves)
- [ ] Task 7: Integration tests — blocked by all above
```

**ASK USER**: "Does this execution order look right? Any tasks that should be reordered or split?"

---

## Phase 3: Orchestrate Execution

### 3.1 Execute by Waves

For each wave, identify all unblocked tasks (no pending `blockedBy` dependencies).

**If 2+ tasks are unblocked and independent:**

Dispatch parallel agents using the `dispatching-parallel-agents` pattern. Send all Task tool calls in a single message:

```
Task(
  subagent_type: "general-purpose",
  description: "Implement [task name]",
  prompt: "[FULL task description from TaskGet — include all context, files, steps, acceptance criteria]",
  run_in_background: true
)
```

**If only 1 task is unblocked:**

Dispatch a single subagent per the `subagent-driven-development` pattern.

### 3.2 Track Progress

After each agent completes:
1. Review the agent's output
2. Verify the work (run tests, check files)
3. Mark task as completed: `TaskUpdate(taskId, status: "completed")`
4. Check TaskList for newly unblocked tasks
5. Dispatch next wave

### 3.3 Handle Failures

If an agent fails a task:
1. Keep task as `in_progress`
2. Create a new subtask describing what needs to be fixed
3. Dispatch a fix agent with the error context
4. Only mark complete after fix is verified

If a blocking task fails:
1. **Do not dispatch blocked tasks** — they will fail too
2. Fix the blocker first
3. Re-verify the fix
4. Then continue with unblocked tasks

### 3.4 Review Between Waves

After each wave completes:
- Show what was implemented
- Show test results
- Show which tasks are now unblocked
- **ASK USER**: "Wave N complete. Ready to proceed with Wave N+1?"

---

## Phase 4: Completion

After all tasks are marked complete:

1. Run full validation: typecheck, lint, test, build
2. Review TaskList to confirm all tasks are completed
3. Use `finishing-a-development-branch` skill to complete the work

## Integration

**Workflow position:** `writing-plans` → **task-orchestration** → `executing-plans` or `subagent-driven-development`

**Required skills:**
- **`writing-plans`** — Creates the plan this skill orchestrates
- **`dispatching-parallel-agents`** — Pattern for parallel agent dispatch
- **`subagent-driven-development`** — Pattern for sequential task execution with review
- **`finishing-a-development-branch`** — Complete development after all tasks

## Key Constraints

- **Background agents can't prompt**: `run_in_background: true` agents auto-deny permission prompts — only use for tasks that don't need user input
- **No shared files in parallel**: Never dispatch parallel agents that edit the same files
- **Full context in prompts**: Subagents don't inherit conversation history — include everything they need
- **Verify before marking complete**: Always run tests/checks before `status: "completed"`
