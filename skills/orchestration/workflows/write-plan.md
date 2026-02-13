# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for our codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. TDD. Frequent commits.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the orchestration skill to create the implementation plan."

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED: Use the Orchestration skill to break this plan into a prioritized task graph with dependencies, then execute using Claude Tasks and Team Agents.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

---
```

## Task Dependencies

**Every plan MUST include a dependency section after all tasks are defined:**

```markdown
## Task Dependencies

Task 1: [name] — no dependencies (Wave 1)
Task 2: [name] — no dependencies (Wave 1)
Task 3: [name] — blocked by Task 1 (Wave 2)
Task 4: [name] — blocked by Tasks 1, 2 (Wave 2)
Task 5: Integration tests — blocked by all (Wave 3)
```

Dependency rules:
- Schema/types before business logic
- Infrastructure/config before features
- TDD pairs (test + implementation) are a single task
- Integration tests after all components exist
- Identify parallel lanes — tasks touching different files with no shared state

## Task Structure

```markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
# Use /commit skill (raw git commit is blocked by hook)
```
```

## Remember
- Exact file paths always
- Complete code in plan (not "add validation")
- Exact commands with expected output
- DRY, YAGNI, TDD, frequent commits

## Execution Handoff

After saving the plan, **automatically proceed to Task Orchestration** unless the user requests otherwise:

**"Plan complete and saved to `docs/plans/<filename>.md`. Proceeding to break this into a prioritized task graph with dependencies for parallel execution."**

**Then immediately use `workflows/orchestrate.md`** to:
1. Analyze the plan and build the dependency graph
2. Create all tasks via TaskCreate with full context and dependencies
3. Present the execution graph organized into waves
4. Ask user approval before executing

**If user explicitly requests an alternative:**

| Request | Workflow | When to Use |
|---------|----------|-------------|
| "Execute with subagents" | `workflows/subagent-dev.md` | Single session, sequential with reviews |
| "Execute in separate session" | `workflows/execute.md` | Parallel session in worktree |

**Default is always Task Orchestration** — it maximizes throughput via parallel waves and provides the best progress tracking via Claude Tasks.
