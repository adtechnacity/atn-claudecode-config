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

Complete ALL audits and fixes before Phase 2.

### 1.1 Code Audit
- Use code-explorer for hot paths, code-reviewer for security/quality
- Use security-scanner for OWASP/CVE, performance-analyzer for bottlenecks
- Fix Critical/High issues immediately

### 1.2 Test Audit
- Use code-reviewer for test quality, code-explorer for coverage gaps
- Write missing high-value tests now
- Tests must pass

### 1.3 Docs Audit
- Use code-explorer to map architecture
- Fix documentation discrepancies

**CHECKPOINT**: All Critical/High fixed, tests passing, docs updated.

---

## Phase 2: Validation (MANDATORY)

Run in order: Type check -> Lint -> Test -> Build. Fix failures before proceeding.

---

## Phase 3: Version Update (MANDATORY - user confirmation)

1. Check current version in project config
2. Analyze changes for bump type:
   - **patch** (0.0.x): Bug fixes
   - **minor** (0.x.0): New features
   - **major** (x.0.0): Breaking changes
3. Present suggested bump, get confirmation
4. Update version file(s)

---

## Phase 4: Build (MANDATORY)

Run production build. For packaging projects, run release command too.

---

## Phase 5: Git Workflow (MANDATORY)

1. `git status` and review
2. Stage files (exclude build artifacts)
3. Commit with heredoc:
   ```bash
   git commit -m "$(cat <<'EOF'
   <type>: <description>
   EOF
   )"
   ```
   Types: feat, fix, update, docs, test, chore

4. Push and tag:

   **Direct push:**
   ```bash
   git tag -a "v$VERSION" -m "Release v$VERSION"
   git push origin <branch> && git push origin "v$VERSION"
   ```

   **PR workflow:**
   ```bash
   git push origin <feature-branch>
   gh pr create --title "Release v$VERSION" --body "Release v$VERSION"
   # After merge:
   git checkout main && git pull && git tag -a "v$VERSION" -m "Release v$VERSION"
   git push origin "v$VERSION"
   ```

---

## Phase 6: Changelog (PROMPT USER)

Ask: "Update CHANGELOG.md?"

If yes:
```bash
/changelog --from=<previous-tag> --to=v$VERSION --append
git add CHANGELOG.md && git commit -m "docs: Update CHANGELOG for v$VERSION" && git push
```

---

## Phase 7: Post-Ship

1. Verify CI/deployment status
2. If issues: use `/rollback`

---

## Deferred Work Policy

**NEVER defer during /ship.** Fix Critical/High issues, write tests, update docs NOW.
