# Changelog

All notable changes to this project will be documented in this file.

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
