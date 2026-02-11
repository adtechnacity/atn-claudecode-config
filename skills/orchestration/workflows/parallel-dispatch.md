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

## Agent Teams

For complex coordination where agents need to **communicate with each other**, use agent teams. Unlike parallel dispatch where agents are fully independent, agent teams let agents share context, coordinate, and avoid duplicate work.

### When to Use Teams vs Independent Dispatch

| Signal | Use Teams | Use Independent Dispatch |
|--------|-----------|------------------------|
| Cross-cutting findings | Agents audit overlapping code areas | Each agent works on separate files |
| Shared root causes | Security + reliability might find same issue | Problems are in different subsystems |
| Duplicate avoidance | Multiple reviewers could report same finding | No overlap in scope |
| Soft dependencies | One agent's output informs another's approach | Tasks are truly isolated |
| Phased execution | Later agents benefit from earlier findings | All agents start and finish independently |

**Default to independent dispatch.** Only use teams when the signals above apply.

### Team Setup Pattern

```
# 1. Create team with unique timestamp
TeamCreate(team_name: "<workflow>-<YYYYMMDD-HHmmss>")

# 2. Spawn teammates (all in a single message for parallel start)
Task(
  subagent_type: "general-purpose",
  team_name: "<workflow>-<YYYYMMDD-HHmmss>",
  name: "agent-name",
  prompt: "...",
  model: "opus"
)

# 3. Create and assign tasks
TaskCreate(subject: "...", description: "...")
TaskUpdate(taskId: "1", owner: "agent-name")

# 4. Coordinate via messages
SendMessage(type: "message", recipient: "agent-name", content: "...", summary: "...")
```

### Communication Patterns

**Finding sharing** — agents post findings as tasks with structured metadata:
```
TaskCreate(
  subject: "XSS in user-input.ts:42",
  description: "Unescaped user input passed to innerHTML...",
  metadata: {type: "finding", severity: "High", phase: 3, files: ["src/user-input.ts"]}
)
```

**Context passing** — lead relays prior findings to next-phase agents:
```
SendMessage(
  type: "message",
  recipient: "next-phase-agent",
  content: "Prior phases found 3 issues in auth/: XSS, missing CSRF, weak hashing. Focus extra attention there. Skip already-reported issues.",
  summary: "Prior findings context for next phase"
)
```

**Dedup** — agents check TaskList before reporting:
```
# Agent checks existing findings before creating a new one
TaskList()  # Review existing findings
# Only create if not already reported
```

### Teardown Pattern

```
# 1. Request shutdown for all agents
SendMessage(type: "shutdown_request", recipient: "agent-1", content: "Work complete")
SendMessage(type: "shutdown_request", recipient: "agent-2", content: "Work complete")

# 2. Wait for confirmations

# 3. Delete team
TeamDelete()
```

### Error Recovery

If a teammate crashes mid-task:
1. Its tasks remain in `in_progress` — mark them back to `pending`
2. Optionally spawn a replacement agent on the same team
3. Remaining agents continue unaffected
4. Lead accounts for missing output in final synthesis

### Stale Team Cleanup

At workflow start, check for leftover teams from crashed previous runs:
```
# Check ~/.claude/teams/ for stale team directories
# If found: TeamDelete() the stale team before creating a new one
```

### Example: Audit With Cross-Cutting Findings

Security scanner finds SQL injection in `db/queries.ts`. Reliability reviewer independently finds the same function lacks error handling. With a team:
- Security scanner posts finding as a task
- Reliability reviewer sees it via TaskList, skips the duplicate, focuses on other error handling gaps
- Result: No duplicate findings, better coverage

### Counter-Example: Test Fixing (No Team Needed)

Three test files failing with unrelated root causes. Each fix agent works on different files with no overlap. A team would add communication overhead with zero benefit. Use independent parallel dispatch instead.

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
