---
description: Prime Claude with project context. Run at session start for faster, more accurate responses.
---

## Integration
Related: **`/init`** (project setup), **`/feature-dev`** (Phase 2 uses similar exploration)

Rapidly build a mental model of the project.

**Principle:** Read selectively, summarize aggressively. Extract what matters for making decisions — never dump raw file contents.

**CLAUDE.md is already loaded automatically.** Don't re-read it. Focus on what CLAUDE.md doesn't cover.

---

## Phase 1: Project Detection

### 1.1 Identify Project Type

```bash
ls -1a
```

Detect from root files:

| Indicator | Project Type |
|-----------|-------------|
| `package.json` + `next.config.*` | Next.js app |
| `package.json` + `vite.config.*` | Vite app (React/Vue/Svelte) |
| `package.json` + `nuxt.config.*` | Nuxt app |
| `package.json` + `astro.config.*` | Astro site |
| `package.json` + no framework config | Node.js library/app |
| `mix.exs` + `lib/*/` | Elixir/Phoenix app |
| `Cargo.toml` | Rust project |
| `pyproject.toml` or `setup.py` | Python project |
| `go.mod` | Go project |
| `pnpm-workspace.yaml` or `workspaces` in package.json | Monorepo |
| `turbo.json` or `nx.json` | Monorepo (Turbo/Nx) |
| `docker-compose.yml` + multiple services | Multi-service architecture |
| `.claude/` only | Claude Code config repo |

### 1.2 Read Project Identity (parallel)

Read these files if they exist — **extract only**: name, purpose, dependencies, scripts, entry points.

- **Root config**: `package.json`, `mix.exs`, `Cargo.toml`, `pyproject.toml`, `go.mod` (name, version, deps, scripts)
- **README.md**: First 2 paragraphs only (purpose and setup)
- **CONTRIBUTING.md**: Skim for workflow rules (if exists)

### 1.3 Detect Build System

| File | Commands |
|------|----------|
| `package.json` | Extract `scripts` object — note typecheck, lint, test, build, dev commands |
| `mix.exs` | Note `deps`, `aliases` |
| `Cargo.toml` | Note `[dependencies]`, `[[bin]]` |
| `Makefile` | Note target names |
| `justfile` | Note recipe names |

---

## Phase 2: Architecture Map

### 2.1 Directory Structure

```bash
ls -1 src/ lib/ app/ packages/ 2>/dev/null
```

For monorepos, also list packages:
```bash
ls -1 packages/ apps/ services/ 2>/dev/null
```

**Goal:** Understand module boundaries. List top-level directories only.

### 2.2 Smart Exploration by Project Type

Launch via Task tool (`subagent_type: "Explore"`, `model: "haiku"`):

**For web apps (Next.js, Vite, Nuxt, Astro):**
> "Map this web app's architecture. Find: routing structure (pages/ or app/ directory), API routes or server functions, shared components directory, state management approach, data fetching patterns, and middleware. List the 10 most important files by architectural significance. Don't read file contents — just map what exists and where."

**For backend services (Node.js, Elixir, Python, Go, Rust):**
> "Map this backend's architecture. Find: entry point, router/controller structure, service/business logic layer, data access layer (models/schemas/repositories), middleware pipeline, and configuration. List the 10 most important files by architectural significance. Don't read file contents — just map what exists and where."

**For libraries/packages:**
> "Map this library's architecture. Find: public API surface (main exports), internal module structure, test organization, build/bundle config, and documentation. List the 10 most important files by architectural significance. Don't read file contents — just map what exists and where."

**For monorepos:**
> "Map this monorepo's structure. For each package/app: identify its purpose, entry point, and key dependencies on other packages. Map the dependency graph between packages. List shared utilities and configurations. Don't read file contents — just map what exists and where."

### 2.3 Key File Sampling

Read **only** 2-3 representative source files to understand coding patterns:
- One main entry point or router
- One business logic / service file
- One test file

Extract from these: naming conventions, import style, error handling pattern, test framework usage. **Summarize the patterns, don't keep the raw content.**

---

## Phase 3: Conventions and Tooling

### 3.1 Detect Conventions (parallel reads, extract key rules only)

| File | Extract |
|------|---------|
| `tsconfig.json` | `strict`, `paths`, `target`, `module` |
| `.eslintrc*` / `eslint.config.*` | Key custom rules, extends |
| `.prettierrc*` / `biome.json` | Print width, tabs/spaces, semicolons |
| `tailwind.config.*` | Custom theme extensions, plugins |
| `.env.example` | Required environment variables (names only, not values) |
| `.github/workflows/*.yml` | CI pipeline steps (skim for test/deploy stages) |
| `Dockerfile` | Base image, build stages |

### 3.2 Detect Testing Setup

```bash
find . -type f \( -name '*.test.*' -o -name '*.spec.*' \) 2>/dev/null | head -5
ls -d test/ tests/ spec/ __tests__/ 2>/dev/null
```

Identify: test runner, test file location pattern, any test utilities or fixtures.

### 3.3 Detect Database

Look for:
- `prisma/schema.prisma` or `drizzle.config.*` — read schema for entity overview
- `migrations/` or `priv/repo/migrations/` — count migrations, read latest one
- `docker-compose.yml` — database services (postgres, mysql, redis, mongo)
- `knexfile.*`, `ormconfig.*`, `typeorm.config.*`

**Schema summary**: List entities/tables and their key relationships. Don't load full schema into response.

---

## Phase 4: Git Context

```bash
git log --oneline -15
git branch --list | head -10
git describe --tags --abbrev=0 2>/dev/null || echo "No tags"
git status --short
```

Extract: recent development focus, current branch, version, uncommitted work.

---

## Phase 5: Output Summary

Present a concise summary — this IS the context that persists in the conversation:

```markdown
## Project: [name]

**Type:** [web app / API / library / monorepo / etc.]
**Stack:** [language, framework, database, test runner]
**Version:** [current tag, commits since]

### Architecture
- [module] — [purpose] ([key files])
- [module] — [purpose] ([key files])
- ...

### Key Patterns
- **Naming:** [camelCase/snake_case, file naming]
- **Imports:** [path aliases, barrel files, etc.]
- **Error handling:** [pattern observed]
- **State:** [management approach]
- **Testing:** [framework, location pattern, style]

### Commands
- Dev: `[command]`
- Test: `[command]`
- Build: `[command]`
- Lint: `[command]`

### Active Context
- Branch: [current]
- Recent focus: [from git log]
- Uncommitted: [yes/no, what]

### Notable
- [Any gotchas, unusual patterns, or things that would trip up an AI agent]
```

---

## Context Budget Rules

1. **Never re-read CLAUDE.md** — it's loaded automatically
2. **Never load node_modules, build output, or lock files**
3. **Never paste full file contents** into the summary — summarize patterns
4. **Schema/model files**: list entities and relationships, not full DDL
5. **Config files**: extract only non-default settings that affect development
6. **README**: first 2 paragraphs for purpose, skip badges and boilerplate
7. **Git history**: 15 commits max, don't load full diffs
8. **Use haiku model** for the Explore agent — fast and cheap for mapping
9. **Total summary should be under 100 lines** — anything longer means you're including too much detail
