---
description: Validate and commit current changes with conventional commit message
---

Commit changes locally after quality checks. Does NOT push.

**ALL steps are MANDATORY. Execute each fully before proceeding.**

## Integration

Enforced by `enforce-commit-skill.sh` (blocks direct `git commit`).

Active hooks: `prevent-secrets-edit.sh`, `format-and-lint.sh`

After committing: `git push`, `/pr`, or `/ship`

## Build System Detection

| Indicator | Type Check | Lint | Test | Build |
|-----------|------------|------|------|-------|
| `package.json` | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | `mypy .` | `ruff check .` | `pytest` | N/A |

Skip unavailable commands.

---

## Step 1: Confirm or Create Branch (PROACTIVE)

**First**, check the current branch and staged changes:

```bash
git branch --show-current
git status --short
```

**Branch logic:**

### If on protected branch (main, master, production, develop):

Commits are blocked by hooks. Must create a feature branch.

**ASK USER** (use AskUserQuestion with options):
- Header: "Branch"
- Question: "You're on `<branch-name>` (protected). What would you like to name your feature branch?"
- Options: Suggest 2-3 branch names based on staged changes
  - Format: `<type>/<short-description>` (kebab-case, 2-4 words)
  - Types: feat, fix, update, docs, test, chore

```bash
git checkout -b "<user-selected-branch-name>"
```

### If on feature branch:

**ASK USER** (use AskUserQuestion with options):
- Header: "Branch"
- Question: "Current branch: `<branch-name>`. Is this the correct branch for these changes?"
- Options:
  - **Continue on current branch** - Use `<branch-name>` for this commit
  - **Create new branch** - Create a new feature branch for this work

**MANDATORY**: Confirm branch before proceeding to Step 2.

---

## Step 2: Quick Quality Check (on changed files)

1. **Security Check**: Scan staged changes for secrets:
   ```bash
   git diff --cached | grep -iE "(api[_-]?key|secret|password|token|credential|AKIA)" || true
   ```
   If secrets detected, **STOP** and alert user.
2. **Quick Review**: Eyeball changed files for obvious issues (no agent dispatch). Thorough audits run via `/ship`.

---

## Step 3: Validation

Run ALL checks. If ANY fails, fix before continuing.

Order: Type check -> Lint -> Test -> Build

---

## Step 4: Simplify Changed Code

Review recently modified files for opportunities to improve clarity and consistency without changing behavior. Launch via Task tool (`subagent_type: "general-purpose"`):

> "You are an expert code simplification specialist focused on enhancing clarity, consistency, and maintainability while preserving exact functionality. Review the changed files and apply refinements that:
>
> **Preserve functionality**: Never change what the code does — only how it does it. All original features, outputs, and behaviors must remain intact.
>
> **Apply project standards**: Follow conventions from CLAUDE.md including import sorting, naming conventions, error handling patterns, and component patterns.
>
> **Enhance clarity**: Reduce unnecessary complexity and nesting. Eliminate redundant abstractions. Improve variable and function names. Consolidate related logic. Remove unnecessary comments that describe obvious code. Avoid nested ternaries — prefer switch/if-else. Choose clarity over brevity — explicit code is better than overly compact code.
>
> **Maintain balance**: Avoid over-simplification. Don't create overly clever solutions, combine too many concerns into single functions, remove helpful abstractions, or prioritize fewer lines over readability. Don't make code harder to debug or extend.
>
> **Scope**: Only refine code that was modified, not surrounding unchanged code. Report file:line and specific suggestions with confidence 0-100, only report >= 80."

Apply improvements. Re-run validation (Step 3) if changes are made.

---

## Step 5: Analyze Changes

```bash
git status
git diff --cached
git log --oneline -10
```

Verify: No unintended files (.env, node_modules), all necessary files included, no debug code.

---

## Step 6: Stage Changes

```bash
git add <files>
```

Include modified/new files. Exclude build artifacts and secrets.

---

## Step 7: Create Commit

### Format

```
<type>: <description>
```

**Types:** `feat` (new feature), `fix` (bug fix), `update` (enhancement/refactor), `docs`, `test`, `chore`

**Rules:** Under 72 chars, sentence case, no period, focus on WHAT/WHY

**Do NOT include:** AI attribution, emojis, body text, generic messages

### Execute

```bash
git commit -m "$(cat <<'EOF'
<type>: <description>
EOF
)"
```

---

## Step 8: Verify

```bash
git status
git log -1
```

---

## Step 9: Next Action (PROMPT USER)

**ASK USER**: "Commit successful! What would you like to do next?"

Present these options:
- **Option A: Push and create PR** - Run `/pr` to push changes and create a pull request
- **Option B: Ship to production** - Run `/ship` for full audits and production release
- **Option C: Done for now** - End here (you can `git push` or continue working later)

**Execute based on user choice:**
- If A: Invoke `/pr` skill
- If B: Invoke `/ship` skill
- If C: Display summary and end

**Note**: Use `/ship` for full security audits before production releases.
