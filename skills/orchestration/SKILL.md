---
name: orchestration
description: Plan, orchestrate, and execute multi-step implementation tasks. USE WHEN writing plans, breaking plans into tasks, executing plans, dispatching parallel agents, subagent-driven development, or finishing development branches.
---

# Orchestration

End-to-end workflow for planning, executing, and completing multi-step development tasks.

## Workflow Routing

| Workflow | Trigger | File |
|----------|---------|------|
| **Write Plan** | "write a plan", "create implementation plan", spec/requirements ready | `workflows/write-plan.md` |
| **Orchestrate Tasks** | "break into tasks", after plan is written/approved | `workflows/orchestrate.md` |
| **Execute Plan** | "execute the plan", "implement the plan" in separate session | `workflows/execute.md` |
| **Subagent Dev** | "execute with subagents", implement in current session | `workflows/subagent-dev.md` |
| **Parallel Dispatch** | 2+ independent tasks, no shared state | `workflows/parallel-dispatch.md` |
| **Finish Branch** | implementation complete, ready to merge/PR/cleanup | `workflows/finish-branch.md` |

## Typical Pipeline

```
WritePlan → Orchestrate → Execute/SubagentDev (using ParallelDispatch) → FinishBranch
```

## Quick Decision

- **Have requirements, no plan yet?** → `WritePlan`
- **Have plan, need task graph?** → `Orchestrate`
- **Have tasks, need execution?** → `Execute` (new session) or `SubagentDev` (this session)
- **Multiple independent tasks?** → `ParallelDispatch`
- **All tasks done?** → `FinishBranch`
