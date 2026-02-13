---
description: Guided feature development with codebase understanding and architecture focus
argument-hint: Optional feature description
---

# Feature Development

## Integration
Related: **`/commit`** (after implementation), **`/ship`** (production release), **`/scan-context`** (Phase 2 uses similar exploration)

You are helping a developer implement a new feature. Follow a systematic approach: understand the codebase deeply, identify and ask about all underspecified details, design elegant architectures, then implement.

## Core Principles

- **Ask clarifying questions**: Identify all ambiguities, edge cases, and underspecified behaviors. Ask specific, concrete questions rather than making assumptions. Wait for user answers before proceeding with implementation. Ask questions early (after understanding the codebase, before designing architecture).
- **Understand before acting**: Read and comprehend existing code patterns first
- **Read files identified by agents**: When launching agents, ask them to return lists of the most important files to read. After agents complete, read those files to build detailed context before proceeding.
- **Simple and elegant**: Prioritize readable, maintainable, architecturally sound code
- **Use Claude Tasks**: Track all progress via TaskCreate/TaskUpdate/TaskList throughout

---

## Phase 1: Discovery

**Goal**: Understand what needs to be built

Initial request: $ARGUMENTS

**Actions**:
1. Create task list with all phases using TaskCreate
2. If feature unclear, ask user for:
   - What problem are they solving?
   - What should the feature do?
   - Any constraints or requirements?
3. Summarize understanding and confirm with user

---

## Phase 2: Codebase Exploration

**Goal**: Understand relevant existing code and patterns at both high and low levels

**Team Setup**:
```
# Clean up stale teams from previous runs
# Check ~/.claude/teams/ for feature-dev-* directories and delete if found

TeamCreate(team_name: "feature-dev-<YYYYMMDD-HHmmss>")
```

**Actions**:
1. Spawn 3 Explore-type teammates on the team (all in a single message):

   ```
   Task(subagent_type: "Explore", team_name: "feature-dev-<ts>", name: "explorer-similar", model: "opus",
     prompt: "Find features similar to [feature] and trace their complete implementation: entry points, call chains, data flow, abstractions. List 5-10 essential files. When you find key patterns, message explorer-arch via SendMessage: 'Found relevant pattern: [name] in [files] — may affect architecture mapping'. Post each key file as a task via TaskCreate(subject: 'Key file: path/to/file.ts', metadata: {type: 'key-file', aspect: 'similar'}).")

   Task(subagent_type: "Explore", team_name: "feature-dev-<ts>", name: "explorer-arch", model: "opus",
     prompt: "Map the architecture for [feature area]: abstraction layers, design patterns, module boundaries, integration points. List 5-10 essential files. When you find module boundaries, message explorer-similar via SendMessage: 'Found module boundary: [description] — relevant to similar feature search'. Post each key file as a task via TaskCreate(subject: 'Key file: path/to/file.ts', metadata: {type: 'key-file', aspect: 'arch'}).")

   Task(subagent_type: "Explore", team_name: "feature-dev-<ts>", name: "explorer-ux", model: "opus",
     prompt: "Analyze [existing feature/area]: execution flow, state changes, side effects, error handling, dependencies, user-facing behavior. List 5-10 essential files. Post each key file as a task via TaskCreate(subject: 'Key file: path/to/file.ts', metadata: {type: 'key-file', aspect: 'ux'}).")
   ```

2. Once the agents return, read all key-file tasks from TaskList. Read those files to build deep understanding.
3. Present comprehensive summary of findings and patterns discovered

---

## Phase 3: Clarifying Questions

**Goal**: Fill in gaps and resolve all ambiguities before designing

**CRITICAL**: This is one of the most important phases. DO NOT SKIP.

**Actions**:
1. Review the codebase findings and original feature request
2. Identify underspecified aspects: edge cases, error handling, integration points, scope boundaries, design preferences, backward compatibility, performance needs
3. **Present all questions to the user in a clear, organized list**
4. **Wait for answers before proceeding to architecture design**

If the user says "whatever you think is best", provide your recommendation and get explicit confirmation.

---

## Phase 4: Architecture Design

**Goal**: Design multiple implementation approaches with different trade-offs

**Phase Transition**: Shutdown Phase 2 explorers, spawn architect teammates on the same team.

```
SendMessage(type: "shutdown_request", recipient: "explorer-similar", content: "Exploration complete")
SendMessage(type: "shutdown_request", recipient: "explorer-arch", content: "Exploration complete")
SendMessage(type: "shutdown_request", recipient: "explorer-ux", content: "Exploration complete")
```

**Actions**:
1. Spawn 3 architect teammates on the same team (all in a single message):

   ```
   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "architect-minimal", model: "opus",
     prompt: "[Full codebase context from Phase 2]. Act as a software architect focused on MINIMAL CHANGES: smallest change, maximum reuse of existing code. Analyze existing patterns with file:line references, make decisive architectural choices with rationale, provide a complete implementation blueprint (files to create/modify, component responsibilities, data flow, phased build sequence). Read other architects' proposals via TaskList to ensure yours is distinct. Post your proposal as a task via TaskCreate(subject: 'Architecture: Minimal', description: '...full proposal...', metadata: {type: 'proposal', approach: 'minimal'}).")

   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "architect-clean", model: "opus",
     prompt: "[Full codebase context from Phase 2]. Act as a software architect focused on CLEAN ARCHITECTURE: ideal structure, maintainability, elegant abstractions. Analyze existing patterns with file:line references, make decisive architectural choices with rationale, provide a complete implementation blueprint. Read other architects' proposals via TaskList to ensure yours is distinct. Post your proposal as a task via TaskCreate(subject: 'Architecture: Clean', description: '...full proposal...', metadata: {type: 'proposal', approach: 'clean'}).")

   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "architect-pragmatic", model: "opus",
     prompt: "[Full codebase context from Phase 2]. Act as a software architect focused on PRAGMATIC BALANCE: speed + quality. Analyze existing patterns with file:line references, make decisive architectural choices with rationale, provide a complete implementation blueprint. Read other architects' proposals via TaskList to ensure yours is distinct. Post your proposal as a task via TaskCreate(subject: 'Architecture: Pragmatic', description: '...full proposal...', metadata: {type: 'proposal', approach: 'pragmatic'}).")
   ```

2. Read all proposal tasks from TaskList. Review all approaches and form your opinion on which fits best for this specific task (consider: small fix vs large feature, urgency, complexity, team context)
3. Present to user: brief summary of each approach, trade-offs comparison, **your recommendation with reasoning**, concrete implementation differences
4. **Ask user which approach they prefer**

---

## Phase 5: Task Graph & Implementation

**Goal**: Break chosen architecture into a prioritized task graph with dependencies, then execute using agent teams

**Phase Transition**: Shutdown Phase 4 architects.

```
SendMessage(type: "shutdown_request", recipient: "architect-minimal", content: "Design complete")
SendMessage(type: "shutdown_request", recipient: "architect-clean", content: "Design complete")
SendMessage(type: "shutdown_request", recipient: "architect-pragmatic", content: "Design complete")
```

**DO NOT START WITHOUT USER APPROVAL**

### 5.1 Build Task Graph

After user approves an architecture approach:

1. Break the chosen architecture into bite-sized tasks (each 2-5 minutes of work)
2. Create all tasks using TaskCreate with:
   - **subject**: Imperative form (e.g., "Implement user auth middleware")
   - **description**: Full context — files to create/modify, steps, acceptance criteria, test requirements. Include ALL context since subagents have no conversation history.
   - **activeForm**: Present continuous (e.g., "Implementing user auth middleware")
3. Set dependencies using TaskUpdate with `addBlockedBy`/`addBlocks`:
   - Schema/types before business logic
   - Infrastructure before features
   - Tests alongside implementation (TDD pairs are one unit)
   - Integration tests after components exist
4. Identify parallel execution lanes — tasks that touch different files with no dependency relationship

### 5.2 Present Execution Graph

Show the user the task graph organized into waves:

```markdown
## Task Execution Graph

### Wave 1 (parallel — no dependencies)
- [ ] Task 1: [name] (S)
- [ ] Task 2: [name] (M)

### Wave 2 (after Wave 1)
- [ ] Task 3: [name] — blocked by Task 1
- [ ] Task 4: [name] — blocked by Tasks 1, 2

### Final
- [ ] Task 5: Integration tests — blocked by all above
```

**ASK USER**: "Does this execution order look right? Any tasks that should be reordered or split?"

### 5.3 Execute by Waves

For each wave, dispatch unblocked tasks using agent teams:

**If 2+ tasks are unblocked and independent:**

Spawn implementation agents as teammates on the existing `feature-dev-<ts>` team (all Task calls in a single message):

```
Task(
  subagent_type: "general-purpose",
  team_name: "feature-dev-<ts>",
  name: "impl-task-N",
  model: "opus",
  description: "Implement [task name]",
  prompt: "[FULL task description from TaskGet — all context, files, steps, acceptance criteria]"
)
```

**If only 1 task is unblocked:**

Dispatch a single subagent with full task context.

### 5.4 Track Progress

After each agent completes:
1. Review the agent's output
2. Verify the work (run tests, check files)
3. Mark task completed: `TaskUpdate(taskId, status: "completed")`
4. Check TaskList for newly unblocked tasks
5. Dispatch next wave

### 5.5 Review Between Waves

After each wave:
- Show what was implemented and test results
- Show which tasks are now unblocked
- **ASK USER**: "Wave N complete. Ready to proceed with Wave N+1?"

### 5.6 Handle Failures

- If agent fails: keep task `in_progress`, create fix subtask, dispatch fix agent
- If blocking task fails: do NOT dispatch blocked tasks — fix blocker first

---

## Phase 6: Quality Review

**Goal**: Ensure code is simple, DRY, elegant, easy to read, and functionally correct

**Actions**:
1. Spawn 3 reviewer teammates on the same team (all in a single message):

   ```
   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "reviewer-simplicity", model: "opus",
     prompt: "Review the implementation for simplicity, DRY, and elegance. Confidence scoring (0-100, only report >= 80). Include file:line and specific fix for each issue. Before concluding, check TaskList for findings from other reviewers to skip duplicates. Post each finding as a task via TaskCreate(subject: '...', metadata: {type: 'finding', category: 'simplicity', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 6, files: ['path']}).")

   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "reviewer-correctness", model: "opus",
     prompt: "Review the implementation for bugs, functional correctness, and edge cases. Confidence scoring (0-100, only report >= 80). Include file:line and specific fix for each issue. Before concluding, check TaskList for findings from other reviewers to skip duplicates. Post each finding as a task via TaskCreate(subject: '...', metadata: {type: 'finding', category: 'correctness', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 6, files: ['path']}).")

   Task(subagent_type: "general-purpose", team_name: "feature-dev-<ts>", name: "reviewer-conventions", model: "opus",
     prompt: "Review the implementation for project conventions, proper abstractions, and integration correctness. Confidence scoring (0-100, only report >= 80). Include file:line and specific fix for each issue. Before concluding, check TaskList for findings from other reviewers to skip duplicates. Post each finding as a task via TaskCreate(subject: '...', metadata: {type: 'finding', category: 'conventions', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 6, files: ['path']}).")
   ```

2. Read all finding tasks from TaskList. Consolidate and identify highest severity issues that you recommend fixing.
3. **Present findings to user and ask what they want to do** (fix now, fix later, or proceed as-is)
4. Address issues based on user decision

---

## Phase 7: Summary

**Goal**: Document what was accomplished

**Actions**:
1. Mark all tasks complete via TaskUpdate
2. Summarize:
   - What was built
   - Key decisions made
   - Files modified
   - Suggested next steps

## Team Teardown

After Phase 6 (or Phase 7 if reviewers are still active):

```
# Shutdown all remaining agents
SendMessage(type: "shutdown_request", recipient: "reviewer-simplicity", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "reviewer-correctness", content: "Review complete")
SendMessage(type: "shutdown_request", recipient: "reviewer-conventions", content: "Review complete")

# After all confirm shutdown
TeamDelete()
```

## Error Recovery

If an explorer/architect/reviewer crashes mid-phase:
1. Continue with remaining agents in that phase (2 out of 3 is still useful)
2. Note the gap in the phase summary
3. Optionally spawn a replacement agent on the same team
4. Do not block the workflow — partial results are valuable

See `workflows/parallel-dispatch.md` "Agent Teams" section for full team coordination patterns.

---
