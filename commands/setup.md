# Project Onboarding

Quickly onboard to a new project or repository.

## Workflow

### Step 1: Gather Project Information

Read key project files:

```bash
# List root contents
ls -la

# Check for common project files
ls README.md CONTRIBUTING.md CLAUDE.md package.json mix.exs Cargo.toml go.mod pyproject.toml .env.example 2>/dev/null
```

**Files to read:**
- `README.md` - Project overview
- `CONTRIBUTING.md` - Development guidelines
- `CLAUDE.md` - Claude-specific context (if exists)
- Package manager files for dependencies

### Step 2: Identify Tech Stack

**Detect frameworks and tools:**

| File | Stack |
|------|-------|
| `package.json` | Node.js (check for React, Next.js, etc.) |
| `mix.exs` | Elixir/Phoenix |
| `Cargo.toml` | Rust |
| `go.mod` | Go |
| `pyproject.toml` | Python |
| `Gemfile` | Ruby |

### Step 3: Map Project Structure

Use Explore agent to understand:
- Directory structure
- Key components and their purposes
- Data flow patterns
- API structure

### Step 4: Identify Build System

**Common scripts to look for:**

```json
// package.json scripts
{
  "dev": "development server",
  "build": "production build",
  "test": "run tests",
  "lint": "code linting",
  "typecheck": "type checking"
}
```

### Step 5: Set Up Local Development

**For Node.js:**
```bash
# Install dependencies
npm install

# Copy environment example
cp .env.example .env.local 2>/dev/null || true

# Run database migrations (if applicable)
npm run db:migrate 2>/dev/null || true

# Start development server
npm run dev
```

**For Elixir:**
```bash
mix deps.get
cp config/dev.secret.exs.example config/dev.secret.exs 2>/dev/null || true
mix ecto.setup
mix phx.server
```

### Step 6: Verify Setup

Run validation commands:

```bash
# Tests
npm test

# Type check
npm run typecheck

# Lint
npm run lint

# Build
npm run build
```

### Step 7: Create CLAUDE.md

If it doesn't exist, create a Claude context file:

```markdown
# Project Name

## Overview
[Brief description]

## Tech Stack
- Framework: [React/Next.js/Phoenix/etc.]
- Language: [TypeScript/Elixir/etc.]
- Database: [PostgreSQL/MongoDB/etc.]
- Testing: [Jest/Vitest/ExUnit/etc.]

## Key Directories
- `src/` - Application source code
- `tests/` - Test files
- `docs/` - Documentation

## Common Commands
- `npm run dev` - Start development server
- `npm test` - Run tests
- `npm run build` - Production build

## Architecture Notes
[Key patterns and decisions]

## Environment Variables
[Required env vars - not values, just names]
```

## Output Format

```markdown
## Project Onboarding Complete

### Project: [Name]

### Tech Stack
| Category | Technology |
|----------|------------|
| Framework | [value] |
| Language | [value] |
| Database | [value] |
| Testing | [value] |

### Structure
```
project/
├── src/           # [description]
├── tests/         # [description]
├── docs/          # [description]
└── ...
```

### Setup Status
- [x] Dependencies installed
- [x] Environment configured
- [x] Database migrated
- [x] Tests passing
- [x] Build succeeds

### Key Commands
| Command | Purpose |
|---------|---------|
| `npm run dev` | Development server |
| `npm test` | Run tests |
| `npm run build` | Production build |

### Notes
[Any issues encountered or special setup requirements]

### Created Files
- `CLAUDE.md` - Project context for Claude
```

## Options

- `/setup --skip-install` - Skip dependency installation
- `/setup --no-claude-md` - Don't create CLAUDE.md
- `/setup --verify-only` - Only run verification, skip setup
