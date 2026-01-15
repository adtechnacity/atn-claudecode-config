---
description: Build, commit, and ship changes to production
---

Ship the current changes to production with comprehensive quality checks.

**CRITICAL**: ALL phases and steps are MANDATORY. Execute each fully before proceeding. Do NOT defer fixes or tests - implement them NOW.

**IMPORTANT**: Execute all steps sequentially. Do NOT stop for user input except for the version update prompt (Phase 3).

## Build System Detection

Detect the project's build system and run appropriate commands:

| Indicator | Build System | Type Check | Lint | Test | Build |
|-----------|--------------|------------|------|------|-------|
| `package.json` | npm/Node.js | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | Elixir/Mix | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | Rust/Cargo | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | Python | `mypy .` | `ruff check .` | `pytest` | N/A |

If a script/command is not available, skip that check.

---

## Phase 1: Audits (MANDATORY - inline execution)

**You MUST complete ALL audits and implement ALL fixes before proceeding to Phase 2.**

Perform these audits inline using their agent integrations. Do NOT defer any work.

### 1. Code Audit (MANDATORY)

Follow audit-code.md inline:
- Use `subagent_type: "feature-dev:code-explorer"` for hot paths analysis
- Use `subagent_type: "feature-dev:code-reviewer"` for security and quality review
- Fix all Critical and High issues immediately (do not defer)
- Medium/Low issues may be noted but prioritize fixing them too

### 2. Test Audit (MANDATORY)

Follow audit-tests.md inline:
- Use `subagent_type: "feature-dev:code-reviewer"` for test quality assessment
- Use `subagent_type: "feature-dev:code-explorer"` for coverage gap analysis
- Write all missing high-value tests now (do not defer)
- Tests must pass before continuing

### 3. Docs Audit (MANDATORY)

Follow audit-docs.md inline:
- Use `subagent_type: "feature-dev:code-explorer"` to map architecture
- Fix any discrepancies in documentation immediately

**CHECKPOINT**: Before proceeding, confirm:
- [ ] All Critical/High code issues fixed
- [ ] All missing tests written and passing
- [ ] All documentation discrepancies resolved

---

## Phase 2: Validation (MANDATORY)

Run ALL available checks using the detected build system. If ANY fails, STOP and fix the issue before retrying.

---

## Phase 3: Version Update (MANDATORY - user confirmation required)

**ALWAYS prompt for confirmation:**

1. Check current version in project configuration (package.json, mix.exs, Cargo.toml, pyproject.toml, etc.)
2. Analyze changes to determine bump type:
   - **patch** (0.0.x): Bug fixes, minor improvements
   - **minor** (0.x.0): New features, significant changes
   - **major** (x.0.0): Breaking changes, major rewrites
3. Present suggested bump with explanation
4. Ask user to confirm, choose different type, or specify custom version
5. Update version in project configuration file(s)

---

## Phase 4: Build (MANDATORY)

Run the production build using the detected build system.

For projects with packaging (npm pack, mix release, cargo build --release), run that too.

---

## Phase 5: Git Workflow (MANDATORY)

Execute ALL steps:

1. Run `git status` and review changes
2. Stage all modified files (exclude build artifacts)
3. Create commit message:
   - Format: `<type>: <description>`
   - Types: feat, fix, update, docs, test, chore
   - Keep concise, no AI attribution
4. Push to the appropriate branch

---

## Commit Message Examples

- `feat: Add user authentication flow`
- `fix: Correct date parsing for timezones`
- `update: Improve query performance with caching`

---

## Deferred Work Policy

**NEVER defer work during /ship.** If an audit identifies issues:
- Critical/High issues: Fix immediately, no exceptions
- Tests: Write them now, not later
- Documentation: Update it now

The only acceptable "deferred" items are truly optional enhancements that don't affect correctness or security.
