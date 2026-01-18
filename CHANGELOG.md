# Changelog

All notable changes to this project will be documented in this file.

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
