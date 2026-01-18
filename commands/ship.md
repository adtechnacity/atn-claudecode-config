---
description: Build, commit, and ship changes to production
---

Ship changes to production with quality checks.

**CRITICAL**: ALL phases are MANDATORY. Execute fully before proceeding. Do NOT defer fixes.

**IMPORTANT**: Execute sequentially. Only stop for version prompt (Phase 3).

## Build System Detection

| Indicator | Type Check | Lint | Test | Build |
|-----------|------------|------|------|-------|
| `package.json` | `npm run typecheck` | `npm run lint` | `npm test` | `npm run build` |
| `mix.exs` | `mix compile --warnings-as-errors` | `mix credo` | `mix test` | `mix compile` |
| `Cargo.toml` | `cargo check` | `cargo clippy` | `cargo test` | `cargo build` |
| `pyproject.toml` | `mypy .` | `ruff check .` | `pytest` | N/A |

Skip unavailable commands.

---

## Phase 1: Audits (MANDATORY)

Run `/audit-all` to completion. This runs all audits sequentially:
- Code audit (security, performance, maintainability)
- Test audit (coverage, quality)
- Docs audit (accuracy)
- Comments audit (relevance)

**CHECKPOINT**: All Critical/High fixed, tests passing, docs updated.

---

## Phase 2: Validation (MANDATORY)

Run in order: Type check -> Lint -> Test -> Build. Fix failures before proceeding.

---

## Phase 3: Version Update (MANDATORY)

1. Check current version: `git tag --sort=-v:refname | head -1`
2. Analyze changes for bump type

**ASK USER** (use AskUserQuestion with options):
- Header: "Version"
- Question: "Version bump for this release? Current: v$CURRENT"
- Options:
  - **v$PATCH (patch)** - Bug fixes, small changes
  - **v$MINOR (minor)** - New features
  - **v$MAJOR (major)** - Breaking changes

3. Update version file(s) if applicable

---

## Phase 4: Build (MANDATORY)

Run production build. For packaging projects, run release command too.

---

## Phase 5: Changelog (PROMPT USER)

**ASK USER** (use AskUserQuestion with options):
- Header: "Changelog"
- Question: "Update CHANGELOG.md for v$VERSION?"
- Options:
  - **Yes** - Add changelog entry for this release
  - **No** - Skip changelog update

If yes, generate changelog content for this version:
```bash
/changelog --from=<previous-tag> --to=v$VERSION --append
```

This must happen BEFORE the git workflow so changelog is included in the release commit.

---

## Phase 6: Git Workflow (MANDATORY)

1. `git status` and review
2. Stage files (exclude build artifacts, include CHANGELOG.md if updated)

3. **Create release branch:**
   ```bash
   git checkout -b "release/v$VERSION"
   ```

4. Commit with heredoc:
   ```bash
   git commit -m "$(cat <<'EOF'
   <type>: <description>
   EOF
   )"
   ```
   Types: feat, fix, update, docs, test, chore

5. **ASK USER** (use AskUserQuestion with options):
   - Header: "Ship method"
   - Question: "How do you want to ship this release?"
   - Options:
     - **Push to main** - Merges to main, creates tag, and pushes
     - **Create PR** - Creates a PR for review before merging

6. Execute chosen workflow:

   **Push to main:**
   ```bash
   git push origin <current-branch>
   git tag -a "v$VERSION" -m "Release v$VERSION"
   git push origin "v$VERSION"
   gh pr create --title "Release v$VERSION" --body "Release v$VERSION" --base main
   gh pr merge --merge --delete-branch
   git checkout main
   git pull origin main
   ```

   **Create PR:**
   ```bash
   git push origin <current-branch>
   gh pr create --title "Release v$VERSION" --body "Release v$VERSION"
   ```
   Stop here. User will merge PR manually later.

---

## Phase 7: GitHub Release (MANDATORY)

Create a GitHub release using the changelog content:

1. Extract release notes for this version from CHANGELOG.md (or use generated notes if no changelog)
2. Create the release:
   ```bash
   gh release create "v$VERSION" --title "v$VERSION - <short description>" --notes "<changelog content for this version>" --verify-tag
   ```

**Release notes format:**
```
## Added
- New feature 1
- New feature 2

## Changed
- Change 1

## Fixed
- Bug fix 1
```

Use `--verify-tag` to ensure the tag exists.

---

## Phase 8: Post-Ship

1. Verify CI/deployment status
2. If issues: use `/rollback`

---

## Deferred Work Policy

**NEVER defer during /ship.** Fix Critical/High issues, write tests, update docs NOW.
