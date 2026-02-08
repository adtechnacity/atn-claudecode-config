---
name: dispatching-parallel-agents
description: Use when facing 2+ independent tasks that can be worked on without shared state or sequential dependencies
---

# Dispatching Parallel Agents

## Overview

When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.

**Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.

## When to Use

**Decision flow:**
- Multiple failures? → Are they independent? → Can they work in parallel?
- If related: single agent investigates all
- If independent but shared state: sequential agents
- If independent and no shared state: **parallel dispatch**

**Use when:**
- 3+ test files failing with different root causes
- Multiple subsystems broken independently
- Each problem can be understood without context from others
- No shared state between investigations

**Don't use when:**
- Failures are related (fix one might fix others)
- Need to understand full system state
- Agents would interfere with each other (editing same files)

## The Pattern

### 1. Identify Independent Domains

Group failures by what's broken:
- File A tests: Tool approval flow
- File B tests: Batch completion behavior
- File C tests: Abort functionality

Each domain is independent - fixing tool approval doesn't affect abort tests.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One test file or subsystem
- **Clear goal:** Make these tests pass
- **Constraints:** Don't change other code
- **Expected output:** Summary of what you found and fixed

### 3. Choose the Right Subagent Type

| Type | Can Do | Use For |
|------|--------|---------|
| `general-purpose` | Read + write files, run commands, search | Fixes, refactors, multi-step tasks |
| `Explore` | Read-only, search, grep, glob | Investigation, codebase research |
| `Bash` | Terminal commands only | Build, test, deploy commands |

**Rule of thumb:** Use `Explore` for investigation, `general-purpose` for fixes.

### 4. Dispatch in Parallel

Send **all independent Task calls in a single message** so they run concurrently. Each call requires three params: `subagent_type`, `prompt`, and `description`.

Use `run_in_background: true` for non-blocking execution — you can continue working while agents run, then check results later.

```
Task(
  subagent_type: "general-purpose",
  description: "Fix abort test failures",
  prompt: "Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts: ...",
  run_in_background: true
)

Task(
  subagent_type: "general-purpose",
  description: "Fix batch completion tests",
  prompt: "Fix the 2 failing tests in src/batch/completion.test.ts: ...",
  run_in_background: true
)

Task(
  subagent_type: "Explore",
  description: "Investigate logging errors",
  prompt: "Find all places where logger.error is called without a stack trace ...",
  run_in_background: true
)
```

### 5. Review and Integrate

When agents return:
- Read each summary
- Verify fixes don't conflict
- Run full test suite
- Integrate all changes

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed (agents do NOT inherit conversation history)
3. **Specific about output** - What should the agent return?

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Return: Summary of what you found and what you fixed.
```

## Key Constraints

- **No nesting:** Agents cannot dispatch sub-agents
- **No conversation history:** Prompts must be fully self-contained with all relevant context
- **Background agents can't prompt:** `run_in_background: true` agents auto-deny permission prompts and cannot use MCP tools
- **One message = parallel:** All Task calls in a single message run concurrently; sequential messages run sequentially

## Agent Teams (Experimental)

For complex coordination where agents need to **communicate with each other**, use agent teams. Unlike parallel dispatch where agents are fully independent, agent teams let agents share context and coordinate.

**Enable with:** `export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`

Use agent teams when:
- Agents need to share intermediate findings
- One agent's output informs another's approach
- Tasks have soft dependencies (not blocking, but informative)

## Common Mistakes

**Wrong:** Too broad — "Fix all the tests" — agent gets lost
**Right:** Specific — "Fix agent-tool-abort.test.ts" — focused scope

**Wrong:** No context — "Fix the race condition" — agent doesn't know where
**Right:** Context — Paste the error messages and test names

**Wrong:** No constraints — Agent might refactor everything
**Right:** Constraints — "Do NOT change production code" or "Fix tests only"

**Wrong:** Vague output — "Fix it" — you don't know what changed
**Right:** Specific — "Return summary of root cause and changes"

**Wrong:** Missing subagent_type — Task call will fail without it
**Right:** Always specify `subagent_type`, `prompt`, and `description`

## When NOT to Use

**Related failures:** Fixing one might fix others — investigate together first
**Need full context:** Understanding requires seeing entire system
**Exploratory debugging:** You don't know what's broken yet
**Shared state:** Agents would interfere (editing same files, using same resources)

## Verification

After agents return:
1. **Review each summary** — Understand what changed
2. **Check for conflicts** — Did agents edit same code?
3. **Run full suite** — Verify all fixes work together
4. **Spot check** — Agents can make systematic errors
