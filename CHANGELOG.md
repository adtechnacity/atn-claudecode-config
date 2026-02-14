# Changelog

All notable changes to this project will be documented in this file.

## [0.5.4] - 2026-02-14

### Added
- **`/review-code`**: New CodeRabbit-style multi-agent code review command — diff-scoped review (branch, PR, or files), 5 specialized agents (change-validator, impact-tracer, correctness-reviewer, security-reviewer, architecture-reviewer), Consumer Map with blast radius scoring, file-by-file inline findings with line references, risk scoring (0-100) with blast radius multiplier, verdict system (APPROVE/APPROVE WITH SUGGESTIONS/REQUEST CHANGES/REJECT), offers to fix issues

### Changed
- **`/review-plan`**: Simplified to focus on plan-level concerns — reduced from 6 agents to 3 (codebase-scout, completeness-analyzer, risk-assessor), removed deep code analysis (consumer maps, blast radius, security scanning, architecture anti-patterns) now handled by `/review-code`, focuses on completeness/gaps, ambiguity, edge cases, task structure, scope assessment, rollback safety, and execution readiness
- **`settings.json`**: Added `Skill(review-code)` permission

## [0.5.3] - 2026-02-13

### Fixed
- **README.md**: Hook architecture diagram now correctly places `dependency-check` and `security-reminder` under PreToolUse (were incorrectly shown under PostToolUse)

### Changed
- **`settings.json`**: Removed ~86 redundant specific Bash permissions — `Bash(bash:*)` already grants all access
- **`/changelog`**, **`/init`**, **`/scan-context`**, **`/feature-dev`**: Added standard `## Integration` sections with cross-references to related commands

## [0.5.2] - 2026-02-13

### Changed
- **`/debug`**: Full rewrite as multi-agent hypothesis-driven debugging engine — 7-phase pipeline (gather context, external intelligence, codebase investigation, hypothesis formation, hypothesis verification, fix implementation, verification & report), Sentry/DevTools/CloudWatch integration for external intelligence gathering, 2-3 parallel Explore agents (error-tracer, change-analyzer, conditional dependency-mapper), structured hypothesis tracking with Phase 4-5 loop (up to 3 attempts before escalation), bug category detection (7 types) driving tool and agent selection, confidence threshold of 70, structured Debug Report with evidence chain

## [0.5.1] - 2026-02-13

### Changed
- **`/review-plan`**: Full rewrite as multi-agent review engine — 7-phase pipeline with 6 specialized agents (codebase-validator, dependency-tracer, impact-analyzer, architecture-reviewer, security-ops-reviewer, debt-docs-reviewer), Consumer Map for blast radius analysis, risk scoring (0-100) with severity weights and blast radius multiplier, CodeRabbit-style report with verdict system (APPROVE/APPROVE WITH CHANGES/REVISE/REJECT), confidence threshold of 75

## [0.5.0] - 2026-02-13

### Added
- **Task graph enforcement**: All plan workflows now create prioritized task graphs with dependencies before execution
- **`write-plan.md`**: Plans now include mandatory Task Dependencies section with wave-based dependency graph
- **`review-plan.md`**: Added Phase 3.2 (Task Dependencies & Prioritization check) and Phase 6 (Execution Handoff to orchestrate.md)

### Changed
- **`feature-dev.md`**: Replaced simple Phase 5 (Implementation) with full Task Graph & Implementation phase — builds dependency graph via TaskCreate/TaskUpdate, presents wave-based execution plan, dispatches team agents per wave, tracks progress via TaskList
- **`write-plan.md`**: Plan execution now auto-flows into Task Orchestration (orchestrate.md) instead of offering 3 equal choices. Plan header instructs Claude to use Tasks + Team Agents
- **`execute.md`**: Replaced simple batch execution with task graph creation, wave identification, and parallel dispatch for independent tasks
- **`orchestrate.md`**: Clarified single-task dispatch (was ambiguously referencing subagent-dev.md as a "pattern")
- **`subagent-dev.md`**: Added task graph creation step — was the only execution path that bypassed task graph enforcement
- **`SKILL.md`**: Updated pipeline to show Orchestrate as default (includes execution), clarified alternative paths (SubagentDev, Execute)
- **`finish-branch.md`**: Added orchestrate.md to "Called by" integration list
- **`review-plan.md`**: Fixed stale `writing-plans` skill reference to `orchestration`

## [0.4.2] - 2026-02-13

### Changed
- **`prune-branches.md`**: Added `dev` to protected branches list in grep filters and safety protocols, fixed markdown formatting (blank lines, table alignment)

## [0.4.1] - 2026-02-13

### Added
- **Klaviyo integration docs**: Added comprehensive Klaviyo MCP documentation to CLAUDE.md with tools table, workflow examples, and usage notes
- **Status line script**: Added `statusline.sh` for Claude Code status bar showing branch, model, context usage, and cost

### Changed
- **CLAUDE.md**: Replaced Brevo MCP reference with Klaviyo, improved markdown formatting with consistent blank lines between sections
- **`statusline.sh`**: Hardened with input validation, empty input handling, numeric clamping, and cost format validation

## [0.4.0] - 2026-02-10

### Added
- **Agent Teams integration**: Upgraded `/audit-code`, `/audit-all`, and `/feature-dev` workflows with inter-agent communication via TeamCreate, SendMessage, TaskCreate, and TaskList
- **`parallel-dispatch.md`**: Expanded Agent Teams section with decision criteria, setup/teardown patterns, communication patterns, error recovery, and examples
- **`orchestrate.md`**: Added "Agent Teams for Soft Dependencies" section for optional team-based execution

### Changed
- **Agents**: All 5 custom agents (security-scanner, performance-analyzer, accessibility-auditor, database-expert, refactoring-expert) upgraded to `model: opus` with team tools (SendMessage, TaskCreate, TaskUpdate, TaskList)
- **`/audit-code`**: Now creates a team with cross-phase context sharing — agents post findings via TaskCreate, later-phase agents check TaskList to avoid duplicates. Supports dual-mode (standalone team vs inside `/audit-all`)
- **`/audit-all`**: Replaced sequential execution with flat mega-team — Wave 1 runs code audit phases + dependency audit in parallel, auto-fix gate between waves, Wave 2 runs test/docs/comments audits in parallel with Wave 1 context
- **`/feature-dev`**: Explorer, architect, and reviewer agents now coordinate via teams — explorers share patterns via SendMessage, architects read each other's proposals via TaskList, reviewers deduplicate findings

## [0.3.9] - 2026-02-10

### Changed
- **Skills**: Reorganized 16 flat skill files into 3 domain directories with SKILL.md routing (`orchestration/`, `design/`, `patterns/`)
- **Skills**: Each domain has a SKILL.md with trigger-based routing table pointing to workflow/context files
- **Skills**: Updated all internal cross-references to use lowercase kebab-case paths
- **Skills**: Renamed `web-audit` to `audit-ui` for consistent `audit-<thing>` naming convention across all audit skills
- **Agents**: Added missing `name` field to `performance-analyzer` and `security-scanner` agents
- **Agents**: Improved all agent descriptions with explicit `USE WHEN` trigger keywords for better auto-matching
- **Skills**: Improved `domain-name-brainstormer` description with trigger keywords

### Removed
- **`using-git-worktrees`**: Removed worktree skill (replaced by external bash script)

## [0.3.8] - 2026-02-10

### Removed
- **`/worktree`**: Removed git worktree management command (use `using-git-worktrees` skill instead)

### Changed
- **`.gitignore`**: Added `image-cache/` and `teams/` to ignored directories
- **`finishing-a-development-branch`**: Updated references from deleted `/worktree` command to `using-git-worktrees` skill

## [0.3.7] - 2026-02-09

### Fixed
- **ralph-loop command**: Wrap `$ARGUMENTS` in heredoc to prevent shell quoting errors from apostrophes and special characters in prompts
- **ralph-loop-setup.sh**: Add single-argument parsing mode with regex-based option extraction for safe heredoc passthrough
- **ralph-loop-setup.sh**: Use `printf` instead of `echo` for user input to avoid flag misinterpretation

## [0.3.6] - 2026-02-09

### Fixed
- **branch-protection.sh**: Added explicit guard for empty branch detection — prevents silent bypass on detached HEAD or non-repo contexts
- **ralph-loop-setup.sh**: Escape `\` and `"` in completion promise YAML to prevent frontmatter corruption
- **ralph-loop-stop.sh**: Cap numeric fields to 6 digits to prevent arithmetic overflow; unescape completion promise when parsing

## [0.3.5] - 2026-02-08

### Added
- **`/worktree`**: Git worktree management command — create, list, remove, and cleanup worktrees for parallel feature development
- **`finishing-a-development-branch`**: Added worktree integration references (pairs with `/worktree`)

### Changed
- `/context-scan` renamed to `/scan-context` — updated all references in README and CHANGELOG
- **CLAUDE.md**: Updated MCP server list — added brevo, cloudflare-dns, gtm (renamed from google-tag-manager-mcp-server), restored snowflake, updated cloudflare description

## [0.3.4] - 2026-02-08

### Added
- **README.md**: Project documentation with usage examples, workflow references, component tables, and architecture diagrams
- **`/codex-review`**: Peer review command using OpenAI Codex agents — spawns 2 parallel agents (correctness + architecture), signal/noise filtering, verdict-based reporting
- **`/scan-context`**: Enhanced with multi-project-type detection (13 types), smart exploration by project type, conventions/tooling detection, context budget rules

### Changed
- `/performance`: Fixed self-references (`/perf` → `/performance`), replaced deprecated FID metric with INP < 200ms
- `/scan-context`: Replaced fragile `ls -1 **/*.test.*` glob with portable `find` command
- `/ship`: Fixed tag creation ordering — tags now created after merge to main (not before)

## [0.3.3] - 2026-02-08

### Added
- **`task-orchestration`** skill: Convert plans into Claude Tasks with dependency graphs, execute in parallel waves with agent teams

### Changed
- `writing-plans` skill: Added Task Orchestration as recommended execution handoff option
- `subagent-driven-development` skill: Fixed stale `code-reviewer` subagent type to `general-purpose`

## [0.3.2] - 2026-02-08

### Added
- **`/sentry-triage`**: Sentry error triage command — scan, categorize, investigate, fix, and update issues across projects
- **`/review-plan`**: Plan review command — gap analysis, edge cases, consistency checks, and improvement suggestions
- **`/fix-pr-comments`**: Automated PR review comment fixer — triage and fix CodeRabbit, CodeScene, SonarCloud, and other bot comments
- **`/audit-ai`**: AI agent readiness audit — evaluate codebase for AI contributor ergonomics, pattern consistency, type safety, documentation, and navigability

### Changed
- `/commit` Step 4: Added code simplification step (from deleted code-simplifier agent) with enriched prompt for clarity, consistency, and maintainability refinement before committing

## [0.3.1] - 2026-02-08

### Changed
- Renamed `/deps` to `/audit-deps` for consistent naming across audit commands
- `/audit-code` Phase 1.2 now invokes `/audit-deps` instead of running raw dependency commands
- `/audit-all` now includes `/audit-deps` as Phase 5 (previously listed as a follow-up)
- Fixed `/perf` reference to `/performance` in `/audit-all`

## [0.3.0] - 2026-02-08

### Added
- **CLAUDE.md**: Project instructions file with MCP servers, CLI tools, coding conventions, and git workflow
- **Skills**: audit-website, dispatching-parallel-agents, executing-plans, finishing-a-development-branch, subagent-driven-development, test-driven-development, using-git-worktrees, web-design-guidelines, writing-plans
- **Commands**: deps (dependency audit and management)
- **Hooks**: format-and-lint.sh (unified formatting and linting on file save)

### Removed
- **Agents**: code-simplifier, feature-dev-code-architect, feature-dev-code-explorer, feature-dev-code-reviewer, git-commit-validator, test-generator, typescript-code-reviewer (replaced by built-in subagent types)
- **Commands**: ralph-loop-help (consolidated), review (consolidated into audit-code)
- **Hooks**: auto-format-on-save.sh, lint-on-save.sh, test-reminder.sh (replaced by format-and-lint.sh)

### Changed
- Consolidated /review into /audit-code with new Bug Review phase and TypeScript-specific review
- Updated all commands to use valid subagent types (Explore, general-purpose) with enriched prompt guidance
- Narrowed overly broad "private"/"secret" patterns in prevent-secrets-edit.sh to specific key patterns
- Corrected inaccurate "Used by" integration references across audit commands
- Removed stale code-simplifier agent references from enforce-commit-skill.sh
- Added AppleScript variable sanitization in notify-on-completion.sh
- Updated frontend-design and schema-designer skills
- Streamlined hooks: branch-protection, enforce-commit-skill, notify-on-completion, ralph-loop-stop, validate-before-push

## [0.2.5] - 2026-01-18

### Added
- `/ship` Phase 0: Sync with Main - rebases feature branch onto latest main before shipping

## [0.2.4] - 2026-01-18

### Changed
- `/ship` now uses `/audit-all` instead of running individual audits
- `/ship` user prompts now use AskUserQuestion with selectable options
- `/commit` branch logic now separates protected vs feature branch handling
- Protected branches no longer offer "continue on current branch" option (blocked by hooks anyway)

## [0.2.3] - 2026-01-18

### Added
- `/audit-all` command to run all audits (code, tests, docs, comments) sequentially

## [0.2.2] - 2026-01-18

### Changed
- `/commit` command now proactively prompts for branch confirmation before starting
- Added Step 8 to `/commit` with interactive next action prompt (PR, Ship, or Done)

## [0.2.0] - 2026-01-18

### Added
- **Agents**: code-simplifier, feature-dev-code-explorer, feature-dev-code-architect, feature-dev-code-reviewer (converted from plugins)
- **Commands**: feature-dev, ralph-loop, cancel-ralph, ralph-loop-help (converted from plugins)
- **Skills**: frontend-design (converted from plugin)
- **Hooks**: ralph-loop-stop.sh, ralph-loop-setup.sh, security-reminder.py (converted from plugins)

### Changed
- Converted 6 plugins (code-simplifier, feature-dev, frontend-design, ralph-loop, security-guidance, typescript-lsp) to local extensions for easier customization
- Updated .gitignore to exclude Claude operational directories and settings
- Fixed hook paths from non-existent directory to ~/.claude/hooks/
- Disabled all converted plugins in enabledPlugins
- Added prune-branches release verification for tag/release branch checking

## [0.1.0] - 2026-01-15

### Added
- Initial Claude Code configuration repository
- **Agents**: accessibility-auditor, database-expert, git-commit-validator, performance-analyzer, refactoring-expert, security-scanner, test-generator, typescript-code-reviewer
- **Commands**: audit-code, audit-comments, audit-docs, audit-tests, changelog, cleanup, commit, context, debug, deps, init, perf, pr, review, rollback, ship
- **Skills**: api-client, api-designer, brand-designer, component-factory, domain-name-brainstormer, error-handler, schema-designer, state-manager
- **Hooks**: branch-protection, dependency-check, lint-on-save, prevent-large-file-edit, prevent-secrets-edit, test-reminder, auto-format-on-save, enforce-commit-skill, notify-on-completion, validate-before-push
- Settings configuration with permissions, model settings, and hook integrations

### Changed
- Simplified documentation across all agents, commands, and skills
- Replaced setup command with settings.json configuration

### Fixed
- Handle branch protection in /ship by creating release branch
- Add user prompt for PR vs merge workflow in /ship
