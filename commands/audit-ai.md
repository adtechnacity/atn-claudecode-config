---
description: Audit codebase for AI agent readiness — optimize for automated contributors
argument-hint: Optional path to scope the audit
---

## Integration

Related: **`/audit-code`** (general quality), **`/audit-docs`** (documentation), **`/init`** (project setup)

Used by: Can be run standalone or as prep before onboarding AI agents to a project

## Purpose

Analyze codebase quality specifically for AI agent contributors. Judge every aspect by how well it enables AI agents to implement features and fix bugs with higher quality and speed. Do NOT anchor to current implementation — evaluate against what the best approach would be for each problem being solved.

**Critical mindset**: Be opinionated. If something works but is structured poorly for AI comprehension, flag it. The goal is a codebase that AI agents can navigate, understand, and modify with minimal context and maximum confidence.

---

## Phase 1: Deep Codebase Exploration

Launch both agents in a single message (`run_in_background: true`):

### 1.1 Architecture Mapper

Launch via Task tool (`subagent_type: "Explore"`, `run_in_background: true`):
> "Map the complete codebase architecture: directory structure, module boundaries, dependency graph, entry points, data flow, and key abstractions. Identify the tech stack, frameworks, and patterns in use. List all configuration files, build systems, and tooling. Note any implicit conventions that aren't documented anywhere. Report file counts and average sizes per directory.
>
> Post each significant finding as a task via TaskCreate:
>   subject: '[Architecture] <brief description>'
>   description: Full details with file references
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 1, audit: 'ai', files: ['path']}
>
> Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'architecture'})"

### 1.2 Critical Path Tracer

Launch via Task tool (`subagent_type: "Explore"`, `run_in_background: true`):
> "Trace the 3-5 most critical execution paths end-to-end: user-facing features, API request lifecycle, data pipelines. For each, note every file touched, every transformation applied, and every decision point. Identify where an AI agent would struggle to follow the flow.
>
> Post each significant finding as a task via TaskCreate:
>   subject: '[Critical Path] <brief description>'
>   description: Full details with file:line references
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 1, audit: 'ai', files: ['path']}
>
> Also post key files: TaskCreate(subject: 'Key file: path/to/file', metadata: {type: 'key-file', aspect: 'critical-path'})"

After both agents return, read all findings and key files from TaskList. Read key files to build deep understanding.

---

## Phase 2: AI Agent Ergonomics Audit

Evaluate each category. For every finding, rate impact on AI agent effectiveness (Critical/High/Medium/Low) and provide a specific fix.

**TaskCreate note**: Post significant findings (severity Critical or High) via TaskCreate with:
```
metadata: {type: 'finding', severity: 'Critical|High', confidence: <0-100>, phase: 2, audit: 'ai', files: ['path']}
```

### 2.1 Context Window Efficiency

AI agents have limited context. Evaluate:

- **File sizes**: Files over 300 lines force agents to work with partial context. Flag files over 500 lines as Critical.
- **Function length**: Functions over 50 lines require too much context to reason about. Flag over 30 lines as a warning.
- **Import chains**: Deep import trees (>3 levels) make it hard to trace dependencies. Map the deepest chains.
- **Circular dependencies**: These confuse AI agents trying to understand module boundaries.
- **Barrel files**: Re-export files (`index.ts`) that obscure where code actually lives.
- **God files/classes**: Single files that handle too many concerns force agents to load unnecessary context.

### 2.2 Pattern Consistency

AI agents learn from patterns. Inconsistency causes incorrect predictions:

- **Multiple ways to do the same thing**: Different error handling patterns, different state management approaches, different API call conventions in the same codebase.
- **Naming inconsistencies**: Mixed conventions (camelCase vs snake_case, plural vs singular, abbreviated vs spelled out).
- **Structural inconsistencies**: Similar features organized differently across modules.
- **Convention violations**: Patterns that contradict the project's own CLAUDE.md or established norms.

### 2.3 Explicitness Over Implicitness

AI agents struggle with magic and implicit behavior:

- **Metaprogramming**: Dynamic method generation, monkey-patching, runtime decorators that aren't visible in source.
- **Convention-over-configuration**: Rails-style magic where behavior depends on file location or naming without explicit wiring.
- **Implicit dependencies**: Global state, singletons, environment variables used deep in the call stack without being passed as parameters.
- **Hidden side effects**: Functions that modify state not obvious from their signature.
- **Framework magic**: Auto-wiring, dependency injection without explicit registration, middleware that's hard to trace.

### 2.4 Type Safety and Contracts

Strong types are an AI agent's best guide:

- **`any` types**: Every `any` is a blind spot where an AI agent has to guess.
- **Missing return types**: Implicit returns force agents to trace through function bodies.
- **Weak validation**: Untyped API boundaries where input shapes are unknown.
- **Missing interfaces**: Complex objects passed around without defined shapes.
- **Discriminated unions**: State variants that aren't properly typed lead to missed edge cases.
- **Generic overuse**: Overly abstract generics that obscure what types actually flow through.

### 2.5 Documentation for AI Agents

What AI agents need is different from what humans need:

- **CLAUDE.md quality**: Does it exist? Does it cover conventions, patterns, architecture decisions, and gotchas? Is it accurate and up-to-date?
- **Architecture documentation**: Can an AI agent understand the system's design without reading every file?
- **API contracts**: Are request/response shapes, error codes, and authentication requirements documented?
- **Decision records**: Why was X chosen over Y? AI agents repeat mistakes without this context.
- **Inline documentation**: Complex algorithms, business rules, and non-obvious logic should have explanations. Obvious code should NOT.
- **Missing README per module**: Complex subdirectories without any explanation of their purpose.

### 2.6 Test Coverage as Guardrails

Tests are how AI agents verify their changes don't break things:

- **Coverage gaps**: Untested business logic means AI agents can't validate their fixes.
- **Test speed**: Slow tests (>30s) discourage AI agents from running them frequently.
- **Test clarity**: Can an AI agent understand what a test verifies from its description alone?
- **Missing integration tests**: Unit tests alone don't catch interaction bugs.
- **Flaky tests**: Tests that sometimes fail erode AI agent confidence in test results.
- **Missing negative tests**: AI agents need to know what should NOT work.

### 2.7 Build and Feedback Loops

Fast feedback helps AI agents iterate:

- **Build time**: Long builds slow iteration cycles.
- **Lint configuration**: Are lint rules comprehensive? Do they catch common AI agent mistakes?
- **Type checking strictness**: Is `strict` mode enabled? Loose type checking lets errors through.
- **CI pipeline clarity**: Can an AI agent understand why CI failed from the output?
- **Error message quality**: Do errors point to the root cause or require investigation?
- **Hot reload / watch mode**: Does the dev environment support fast iteration?

### 2.8 Dependency and Module Boundaries

Clear boundaries help AI agents scope their changes:

- **Unclear module ownership**: Which module owns which concern?
- **Leaky abstractions**: Internal details exposed across module boundaries.
- **Missing API layers**: Direct database access from UI components, bypassing service layers.
- **Tightly coupled modules**: Changing one module requires understanding and modifying others.
- **Unused dependencies**: Noise that confuses AI agents about what's actually needed.

### 2.9 Code Navigability

How easily can an AI agent find what it needs:

- **File organization**: Is related code colocated? Or scattered across distant directories?
- **Naming clarity**: Can an AI agent find the right file from a feature description alone?
- **Search-friendly code**: Are key concepts named explicitly, or hidden behind abbreviations and acronyms?
- **Dead code**: Unused functions, unreachable branches, commented-out code — all noise that wastes AI context.
- **Configuration sprawl**: Settings spread across many files with unclear precedence.

---

## Phase 3: Architecture Assessment

**Cross-phase context relay**: Before dispatching this agent, read all findings from TaskList (Phases 1-2). Build a summary of the key findings and embed it in the agent prompt so it has full context from prior phases.

Evaluate the overall architecture — not how it IS, but how it SHOULD BE for the problem being solved:

- **Is the architecture appropriate for the problem?** A simple CRUD app shouldn't have microservice complexity. A complex domain shouldn't be in a single file.
- **Are abstractions at the right level?** Over-abstraction is as bad as under-abstraction for AI agents.
- **Are there simpler alternatives?** For each complex pattern, consider if a simpler approach would solve the same problem.
- **Is the codebase growing in a sustainable direction?** Will adding features require touching many files, or are new features isolated?

Launch via Task tool (`subagent_type: "general-purpose"`):

> "You are a senior software architect. Evaluate this codebase's architecture against the problem it solves. Don't anchor to the current implementation — assess whether the chosen patterns, abstractions, and structure are the best approach for this domain. Flag: over-engineering, under-engineering, mismatched patterns (e.g., microservice patterns in a monolith), premature abstractions, and missing abstractions. For each finding, suggest the ideal approach with rationale.
>
> **Context from prior phases:**
> [EMBED Phase 1-2 findings summary from TaskList here]
>
> Post each finding as a task via TaskCreate:
>   subject: '[Architecture] <brief description>'
>   description: Full details with file references and rationale
>   metadata: {type: 'finding', severity: 'Critical|High|Medium|Low', confidence: <0-100>, phase: 3, audit: 'ai', files: ['path']}"

---

## Phase 4: Prioritized Remediation Plan

Read all findings from TaskList (filter by `metadata.audit: "ai"`) to build the remediation plan from structured data.

### 4.1 Categorize All Findings

| Priority | Criteria | Timeline |
|----------|----------|----------|
| **P0 — Blocking** | AI agents cannot work effectively without fixing this | Immediate |
| **P1 — High Impact** | Significantly slows AI agent productivity | This sprint |
| **P2 — Improvement** | Would noticeably improve AI agent experience | Next sprint |
| **P3 — Nice to Have** | Minor improvement, address opportunistically | Backlog |

### 4.2 Create Phased Plan

Organize fixes into phases that build on each other:

**Phase A: Foundation** (do first)
- CLAUDE.md creation or overhaul
- Type safety improvements (remove `any`, add interfaces)
- Critical test coverage gaps

**Phase B: Structure** (after foundation)
- File splitting (break up god files)
- Pattern standardization (pick one way, apply everywhere)
- Module boundary enforcement

**Phase C: Polish** (after structure)
- Documentation improvements
- Dead code removal
- Build/lint optimization
- Naming improvements

### 4.3 Present Plan

```markdown
## AI Agent Readiness Audit: [Project Name]

**Overall Score**: X/10 (where 10 = optimally AI-agent-friendly)

### Scorecard
| Category | Score | Key Issue |
|----------|-------|-----------|
| Context Window Efficiency | /10 | |
| Pattern Consistency | /10 | |
| Explicitness | /10 | |
| Type Safety | /10 | |
| Documentation | /10 | |
| Test Coverage | /10 | |
| Build & Feedback | /10 | |
| Module Boundaries | /10 | |
| Navigability | /10 | |

### P0 — Blocking Issues
| # | Category | File(s) | Issue | Fix |
|---|----------|---------|-------|-----|

### P1 — High Impact
| # | Category | File(s) | Issue | Fix |
|---|----------|---------|-------|-----|

### P2 — Improvements
| # | Category | File(s) | Issue | Fix |
|---|----------|---------|-------|-----|

### P3 — Nice to Have
| # | Category | File(s) | Issue | Fix |
|---|----------|---------|-------|-----|

### Remediation Phases
**Phase A**: [list tasks, estimated scope]
**Phase B**: [list tasks, estimated scope]
**Phase C**: [list tasks, estimated scope]
```

**ASK USER**: Present the full report and ask which phase to begin, or if they want to generate a detailed implementation plan.

## Error Recovery

If an agent crashes mid-phase:
1. Phase 1: The other parallel agent's findings are still valid — continue with partial context
2. Phase 2: Lead-driven, no agent to crash — but if interrupted, resume from the last category evaluated
3. Phase 3: Partial Phase 1-2 context is still useful for architecture assessment — note the gap
4. Do not block on partial failure — partial results are valuable

## Options

- `/audit-ai` - Full AI readiness audit of current project
- `/audit-ai <path>` - Audit a specific directory or module
