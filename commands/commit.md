---
description: Validate and commit current changes with conventional commit message
---

Commit the current changes locally after ensuring the codebase passes all quality checks.

**IMPORTANT**: This command commits locally only - it does NOT push to the repository.

**CRITICAL**: ALL steps below are MANDATORY. Execute each step fully before proceeding to the next. Do NOT skip any step.

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

## Step 1: Code Quality (MANDATORY - on changed files only)

**You MUST execute this step before validation.** Do NOT skip to Step 2.

1. **Simplify Code**: Invoke Task tool with `subagent_type: "code-simplifier:code-simplifier"` on modified files
   - Simplifies and refines code for clarity and consistency
   - Focuses on recently modified code
   - Wait for completion before continuing

2. **Audit Comments**: Follow audit-comments.md inline on modified files
   - Remove redundant/outdated comments
   - Add missing explanations for complex logic
   - Use `subagent_type: "feature-dev:code-reviewer"` for quality review
   - Use `subagent_type: "feature-dev:code-explorer"` for codebase navigation
   - Apply all recommended changes before continuing

---

## Step 2: Validation (MANDATORY)

Run ALL available checks using the detected build system. If ANY fails, STOP and fix the issue before retrying.

---

## Step 3: Analyze Changes (MANDATORY)

```bash
git status              # See modified, added, deleted files
git diff                # Review actual code changes
git log --oneline -10   # Recent commit message patterns
```

---

## Step 4: Stage Changes (MANDATORY)

- Include all modified and new files that are part of the change
- Exclude build artifacts
- Do NOT stage files containing secrets (.env, credentials, API keys)

---

## Step 5: Create Commit (MANDATORY)

### Commit Message Format

```
<type>: <description>
```

**Types:**
- `feat` - New feature or significant functionality
- `fix` - Bug fix or error correction
- `update` - Enhancement, refactoring, or improvement
- `docs` - Documentation-only changes
- `test` - Adding or updating tests
- `chore` - Maintenance, dependency updates, tooling

**Guidelines:**
- Keep under 72 characters
- Sentence case, no period at end
- Focus on WHAT and WHY, not HOW

**Examples:**
- `feat: Add user authentication flow`
- `fix: Correct date parsing for timezones`
- `update: Improve query performance with caching`

**DO NOT include:** AI attribution, emoji prefixes, body text, generic messages

---

## Step 6: Verify Commit (MANDATORY)

```bash
git status    # Confirm working directory is clean
git log -1    # Display the created commit
```

---

## Notes

- This command is for LOCAL commits only
- Use `/ship` to push changes to the repository
- Secrets and sensitive files should never be committed
