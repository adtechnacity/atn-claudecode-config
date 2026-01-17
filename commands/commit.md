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

## Step 1: Ensure Feature Branch

Before any work, verify you're on a feature branch:

```bash
CURRENT_BRANCH=$(git branch --show-current)
if [[ "$CURRENT_BRANCH" =~ ^(main|master|production|develop)$ ]]; then
  # MUST create feature branch before proceeding
  # Branch naming: <type>/<short-description> (kebab-case, 2-4 words)
  # Example: feat/add-user-auth, fix/login-bug, chore/update-deps
  git checkout -b "<type>/<short-description>"
fi
```

**This is MANDATORY.** Do NOT proceed if on a protected branch.

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

## After Committing

- `git push` - Push to remote (validate-before-push.sh runs)
- `/pr` - Create pull request
- `/ship` - Full production release

Secrets should never be committed. Use `/ship` for full audits.
