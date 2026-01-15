---
description: Initialize Claude configuration for a project. Creates CLAUDE.md and recommended settings.
---

# Project Initialization

Set up Claude Code configuration for a project.

## Steps

### 1. Analyze Project
- Detect language/framework
- Find linting/formatting config
- Identify test framework
- Find build/run scripts

### 2. Create CLAUDE.md

```markdown
# Project Name

## Overview
[Brief description]

## Tech Stack
- Language:
- Framework:
- Database:
- Testing:

## Directory Structure
src/     # Source code
tests/   # Test files

## Commands
- `npm run dev` - Development server
- `npm test` - Run tests
- `npm run build` - Production build

## Code Style
[Linting/formatting rules]

## Conventions
[Naming, file organization, git workflow]
```

### 3. Create .claude/settings.json
Add project-specific permissions if needed.

### 4. Set Up Versioning

Check for version field in package.json, mix.exs, Cargo.toml, or pyproject.toml.

If missing, add `"version": "0.1.0"` (or equivalent).

If repo has commits but no tags:
```bash
git tag -a "v0.1.0" -m "Initial release"
```

### 5. Suggest Additional Setup
Recommend helpful MCP servers.
