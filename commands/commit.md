---
description: Validate and commit current changes with conventional commit message
---

Commit changes locally after quality checks. Does NOT push.

**ALL steps are MANDATORY. Execute each fully before proceeding.**

## Integration

Enforced by `enforce-commit-skill.sh` (blocks direct `git commit`).

Active hooks: `prevent-secrets-edit.sh`, `auto-format-on-save.sh`

Related: `git-commit-validator` agent, `security-scanner` agent

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

**Always prompt the user** - they may be working on something different from the current branch:

**ASK USER**: "Current branch: `<branch-name>`. Is this the correct branch for these changes?"

Present options:
- **Continue on current branch** - Use `<branch-name>` for this commit
- **Create new branch** - Create a new feature branch for this work

**If creating a new branch:**
Suggest format: `<type>/<short-description>` (kebab-case, 2-4 words)
- Examples: `feat/add-user-auth`, `fix/login-bug`, `chore/update-deps`
- Types: feat, fix, update, docs, test, chore

```bash
git checkout -b "<user-provided-branch-name>"
```

**MANDATORY**: Confirm branch before proceeding to Step 2.

---

## Step 2: Code Quality (on changed files)

1. **Simplify Code**: Task tool with `subagent_type: "code-simplifier:code-simplifier"`
2. **Audit Comments**: Follow audit-comments.md; use `feature-dev:code-reviewer` and `feature-dev:code-explorer`
3. **Security Check**:
   ```bash
   git diff --cached | grep -iE "(api[_-]?key|secret|password|token|credential|AKIA)" || true
   ```
   If secrets detected, **STOP** and alert user.

---

## Step 3: Validation

Run ALL checks. If ANY fails, fix before continuing.

Order: Type check -> Lint -> Test -> Build

---

## Step 4: Analyze Changes

```bash
git status
git diff --cached
git log --oneline -10
```

Verify: No unintended files (.env, node_modules), all necessary files included, no debug code.

---

## Step 5: Stage Changes

```bash
git add <files>
```

Include modified/new files. Exclude build artifacts and secrets.

---

## Step 6: Create Commit

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

## Step 7: Verify

```bash
git status
git log -1
```

---

## Step 8: Next Action (PROMPT USER)

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
