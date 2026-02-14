# Claude Code Configuration

Commands, skills, hooks, and agents for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) that automate development workflows — from project setup to production releases.

## Usage Examples

### Start a new product

```
/scan-context
```
```
I'm building a SaaS analytics dashboard for e-commerce stores.
Tech stack: Next.js 15, PostgreSQL, Tailwind, deployed on Vercel.
Set up the project structure and initialize everything.
```
```
/feature-dev Add the main dashboard page with real-time revenue metrics
```
```
/commit
```

### Build a major feature

```
/feature-dev Add user authentication with OAuth (Google, GitHub),
session management, role-based access control, and account settings page
```
> Walks through 7 phases: discovery, exploration, clarification, architecture, implementation, review, summary.

### Plan first, review, then execute

```
/feature-dev Plan a notification system with email, in-app, and push channels
```
```
/review-plan docs/plans/2026-02-08-notifications.md
```
```
Use orchestration to break this plan into tasks and execute it
```

### Quick fix

```
The login button on mobile is cut off on screens under 375px.
Fix it and make sure it's responsive down to 320px.
```
```
/commit
```

### Debug and investigate

```
/debug Users are getting a blank screen after clicking "Export to CSV"
```
```
/sentry-triage analytics-dashboard
```

### Fix PR review comments

```
/fix-pr-comments 42
```
> Triages CodeRabbit/CodeScene/SonarCloud comments, fixes valid issues, drafts responses for false positives.

### Ship to production

```
/ship
```
> Syncs with main, runs all audits, validates, versions, builds, changelog, pushes, releases.

### Audit and improve

```
/audit-all                    # Full audit: code, tests, docs, comments, deps
/audit-ai                     # AI agent readiness audit (scored report)
/performance frontend         # Core Web Vitals via Chrome DevTools
/performance db               # Query analysis with EXPLAIN ANALYZE
```

### Autonomous development

```
/ralph-loop "Increase test coverage to 80%" --max-iterations 10
```

### Codex peer review

```
/codex-review                 # Review current branch with Codex agents
/codex-review 42              # Review PR #42
```
> Spawns 2 parallel Codex agents (correctness + architecture), synthesizes findings with signal/noise filtering.

### Design and architecture

```
Design the database schema for a multi-tenant project management app
```
> Auto-invokes `schema-designer`, `api-designer`, `component-factory`, `frontend-design` based on context.

### Clean up

```
/cleanup                      # Remove dead code
/prune-branches --execute     # Remove merged branches
```

---

## Workflows

### Development

| Flow | Commands |
|------|----------|
| **New project** | `/init` → `/scan-context` → `/feature-dev` → `/commit` → `/ship` |
| **Major feature** | `/feature-dev` → `orchestration` > `write-plan` → `/review-plan` → `orchestration` > `orchestrate` → `/commit` → `/ship` |
| **Quick change** | (edit) → `/commit` → `/pr` or `/ship` |
| **Debug** | `/debug` or `/sentry-triage` → fix → `/commit` |
| **Autonomous** | `/ralph-loop` → `/cancel-ralph` when done |

### Quality

| Command | Focus |
|---------|-------|
| `/audit-all` | Run all audits sequentially with quality gates |
| `/audit-code` | Security, performance, maintainability, reliability, bugs |
| `/audit-tests` | Coverage gaps, redundant tests, test quality |
| `/audit-docs` | README, CLAUDE.md, API docs accuracy |
| `/audit-comments` | Remove noise comments, add missing explanations |
| `/audit-deps` | Security vulnerabilities, outdated packages, unused deps |
| `/audit-ai` | AI agent readiness (scored X/10 per category) |

### Standalone Tools

| Tool | Purpose |
|------|---------|
| `/cleanup` | Dead code removal |
| `/performance` | Frontend, backend, database performance analysis |
| `/rollback` | Safely revert commits, releases, files, or tags |
| `/prune-branches` | Remove merged branches |
| `/changelog` | Generate changelog from git history |
| `/review-plan` | Review implementation plans for gaps |
| `/codex-review` | Peer review with OpenAI Codex agents |
| `/fix-pr-comments` | Fix automated PR review comments |
| `/scan-context` | Prime Claude with project context |

---

## Component Reference

### Commands

| Command | Description |
|---------|-------------|
| `/init` | Initialize Claude config for a project |
| `/scan-context` | Prime Claude with project context |
| `/feature-dev` | Guided 7-phase feature development |
| `/commit` | Validate, simplify, and commit |
| `/pr` | Create a pull request |
| `/ship` | Full production release workflow |
| `/debug` | Systematic debugging framework |
| `/sentry-triage` | Sentry error triage and fixing |
| `/fix-pr-comments` | Fix automated PR review comments |
| `/review-plan` | Review implementation plans for gaps |
| `/codex-review` | Peer review with OpenAI Codex agents |
| `/audit-all` | Run all audits sequentially |
| `/audit-code` | Code quality audit |
| `/audit-tests` | Test coverage audit |
| `/audit-docs` | Documentation audit |
| `/audit-comments` | Comment quality audit |
| `/audit-deps` | Dependency audit |
| `/audit-ai` | AI agent readiness audit |
| `/performance` | Performance analysis |
| `/cleanup` | Dead code removal |
| `/rollback` | Safe rollback |
| `/changelog` | Generate changelog |
| `/prune-branches` | Remove merged branches |
| `/ralph-loop` | Autonomous development loop |
| `/cancel-ralph` | Cancel active Ralph Loop |

### Skills

Auto-invocable capabilities that provide patterns, templates, and specialized knowledge.

**Workflow:**

| Skill | Purpose |
|-------|---------|
| `orchestration` > `write-plan` | Implementation plans with bite-sized tasks |
| `orchestration` > `execute` | Batch execution with review checkpoints |
| `orchestration` > `subagent-dev` | Fresh subagent per task + 2-stage review |
| `orchestration` > `orchestrate` | Claude Tasks with dependencies and parallel waves |
| `orchestration` > `parallel-dispatch` | Run independent tasks concurrently |
| `orchestration` > `finish-branch` | Verify, merge/PR, clean up branch |
| `test-driven-development` | Red-Green-Refactor enforcement |

**Design & Architecture:**

| Skill | Purpose |
|-------|---------|
| `frontend-design` | Production-grade UI avoiding generic AI patterns |
| `design` > `audit-ui` | Vercel Web Interface Guidelines review |
| `component-factory` | UI components (React, Vue, Svelte) with a11y |
| `design` > `brand-design` | Brand identity, logos, color palettes, typography |
| `schema-designer` | Database schema with normalization and indexing |
| `api-designer` | REST/GraphQL API design with OpenAPI specs |
| `api-client` | Type-safe API clients with retries and auth |
| `error-handler` | Error handling patterns |
| `state-manager` | State management (Context, Zustand, Redux, Pinia) |
| `domain-name-brainstormer` | Domain name generation and availability |
| `audit-website` | Website audit: SEO, performance, security (230+ rules) |

### Hooks

| Hook | Trigger | Purpose |
|------|---------|---------|
| `branch-protection.sh` | PreToolUse (Bash) | Block commits/pushes to protected branches |
| `enforce-commit-skill.sh` | PreToolUse (Bash) | Require `/commit` over raw `git commit` |
| `prevent-secrets-edit.sh` | PreToolUse (Edit/Write) | Block edits to secret-containing files |
| `prevent-large-file-edit.sh` | PreToolUse (Edit/Write) | Block edits to oversized files |
| `validate-before-push.sh` | PreToolUse (Bash) | Warn before push, block force-push |
| `format-and-lint.sh` | PostToolUse (Edit/Write) | Auto-format and lint after edits |
| `dependency-check.sh` | PreToolUse (Bash) | Check for dependency changes |
| `notify-on-completion.sh` | PostToolUse (Bash) | Desktop notification on long commands |
| `security-reminder.py` | PreToolUse (Edit/Write/MultiEdit) | Security reminders |
| `ralph-loop-setup.sh` | Bash | Initialize Ralph Loop state |
| `ralph-loop-stop.sh` | Stop | Manage Ralph Loop iteration |

### Agents

| Agent | Expertise |
|-------|-----------|
| `security-scanner` | OWASP Top 10, secret detection, dependency CVEs |
| `performance-analyzer` | Bottleneck identification, profiling, optimization |
| `accessibility-auditor` | WCAG 2.1 compliance, a11y testing |
| `database-expert` | Query optimization, schema design, migrations |
| `refactoring-expert` | Safe code restructuring without behavior changes |

---

## Architecture

```
                         ┌─────────────┐
                         │   /init     │  Project setup
                         └──────┬──────┘
                                │
                         ┌──────▼──────┐
                         │/scan-context│  Load context
                         └──────┬──────┘
                                │
              ┌─────────────────┼─────────────────┐
              │                 │                  │
      ┌───────▼──────┐  ┌──────▼──────┐  ┌───────▼───────┐
      │ /feature-dev │  │   (edit)    │  │    /debug     │
      │  7 phases    │  │  directly   │  │  systematic   │
      └───────┬──────┘  └──────┬──────┘  └───────┬───────┘
              │                │                  │
      ┌───────▼──────┐        │          ┌───────▼───────┐
      │  write-plan  │        │          │/sentry-triage │
      └───────┬──────┘        │          └───────┬───────┘
              │                │                  │
      ┌───────▼──────┐        │                  │
      │ /review-plan │        │                  │
      └───────┬──────┘        │                  │
              │                │                  │
     ┌────────▼────────┐      │                  │
     │  orchestrate   │      │                  │
     │  or subagent-  │      │                  │
     │  dev           │      │                  │
     │  or execute    │      │                  │
     │               │      │                  │
     └────────┬────────┘      │                  │
              │                │                  │
              └────────┬───────┴──────────────────┘
                       │
                ┌──────▼──────┐
                │   /commit   │  Validate + simplify + commit
                └──────┬──────┘
                       │
              ┌────────┼────────┐
              │        │        │
       ┌──────▼──┐ ┌───▼───┐   │
       │   /pr   │ │ /ship │   │ (done)
       └─────────┘ └───┬───┘
                       │
            ┌──────────┼──────────┐
            │          │          │
     ┌──────▼──┐ ┌─────▼────┐ ┌──▼────────┐
     │/audit-  │ │/changelog│ │  GitHub   │
     │  all    │ │          │ │  Release  │
     └─────────┘ └──────────┘ └───────────┘
```

### Hook Enforcement

```
          ┌────────────────────┬────────────────────┐
          │                    │                     │
  ┌───────▼───────┐  ┌────────▼────────┐  ┌────────▼────────┐
  │  PreToolUse   │  │  PostToolUse    │  │     Stop        │
  │               │  │                 │  │                 │
  │ branch-       │  │ format-and-     │  │ ralph-loop-     │
  │  protection   │  │  lint           │  │  stop           │
  │ enforce-      │  │ notify-on-      │  │                 │
  │  commit-skill │  │  completion     │  │                 │
  │ prevent-      │  │                 │  │                 │
  │  secrets-edit │  │                 │  │                 │
  │ prevent-      │  │                 │  │                 │
  │  large-file   │  │                 │  │                 │
  │ validate-     │  │                 │  │                 │
  │  before-push  │  │                 │  │                 │
  │ dependency-   │  │                 │  │                 │
  │  check        │  │                 │  │                 │
  │ security-     │  │                 │  │                 │
  │  reminder     │  │                 │  │                 │
  └───────────────┘  └─────────────────┘  └─────────────────┘
```

### MCP Integrations

| Server | Use Case |
|--------|----------|
| **sentry** | Error tracking, triage (`/sentry-triage`, `/debug`) |
| **chrome-devtools** | Browser debugging, performance profiling (`/performance`) |
| **cloudflare** | DNS, Workers, R2, D1, KV, Queues |
| **analytics-mcp** | Google Analytics reporting |
| **aws-cloudwatch** | CloudWatch logs, metrics, alarms |
| **growthbook** | Feature flags and A/B testing |
| **context7** | Library and API documentation lookup |
| **gtm** | Google Tag Manager |
| **snowflake** | Data warehouse queries |

---

## Configuration

- **`CLAUDE.md`** — Global coding conventions, MCP servers, CLI tools, git workflow rules
- **`settings.json`** — Permissions, hooks, model selection, UI preferences
- **`settings.local.json`** — Local overrides (not committed)

Versioned with semver tags. See [CHANGELOG.md](CHANGELOG.md) for release history.
