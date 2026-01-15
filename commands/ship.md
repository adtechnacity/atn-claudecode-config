---
description: Build, commit, and ship changes to production
---

Ship the current changes to production with comprehensive quality checks.

**CRITICAL**: ALL phases and steps are MANDATORY. Execute each fully before proceeding. Do NOT defer fixes or tests - implement them NOW.

**IMPORTANT**: Execute all steps sequentially. Do NOT stop for user input except for the version update prompt (Phase 3).

## Integration

Active hooks during this workflow:
- **`enforce-commit-skill.sh`** - Ensures commit follows quality workflow
- **`prevent-secrets-edit.sh`** - Blocks edits to sensitive files
- **`auto-format-on-save.sh`** - Auto-formats files after edits
- **`validate-before-push.sh`** - Validates before git push (warns about protected branches)
- **`notify-on-completion.sh`** - Desktop notification when builds complete

Related agents:
- **`git-commit-validator`** - Handles commit validation
- **`security-scanner`** - Comprehensive security audit
- **`performance-analyzer`** - Performance bottleneck analysis
- **`typescript-code-reviewer`** - TypeScript code quality (if applicable)

Related commands:
- **`/commit`** - Used internally for the commit step
- **`/rollback`** - If something goes wrong after shipping

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

### 1.1 Code Audit (MANDATORY)

Follow audit-code.md inline:
- Use `subagent_type: "feature-dev:code-explorer"` for hot paths analysis
- Use `subagent_type: "feature-dev:code-reviewer"` for security and quality review
- Use `security-scanner` agent for comprehensive OWASP/CVE analysis
- Use `performance-analyzer` agent for performance bottleneck detection
- Fix all Critical and High issues immediately (do not defer)
- Medium/Low issues may be noted but prioritize fixing them too

### 1.2 Test Audit (MANDATORY)

Follow audit-tests.md inline:
- Use `subagent_type: "feature-dev:code-reviewer"` for test quality assessment
- Use `subagent_type: "feature-dev:code-explorer"` for coverage gap analysis
- For TypeScript projects, use `typescript-code-reviewer` agent
- Write all missing high-value tests now (do not defer)
- Tests must pass before continuing

### 1.3 Docs Audit (MANDATORY)

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

**Validation order:**
1. Type check
2. Lint
3. Test
4. Build

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

**Note:** The `notify-on-completion.sh` hook will send a desktop notification when the build completes.

---

## Phase 5: Git Workflow (MANDATORY)

Execute ALL steps:

1. Run `git status` and review changes
2. Stage all modified files (exclude build artifacts)
3. Create commit message:
   - Format: `<type>: <description>`
   - Types: feat, fix, update, docs, test, chore
   - Keep concise, no AI attribution
   - Use heredoc format (required by enforce-commit-skill.sh):
     ```bash
     git commit -m "$(cat <<'EOF'
     <type>: <description>
     EOF
     )"
     ```
4. Push to the appropriate branch
   - The `validate-before-push.sh` hook will:
     - Warn if uncommitted changes exist
     - Block force-push to protected branches (main, master)
     - Remind about `/ship` workflow

---

## Phase 6: Post-Ship (RECOMMENDED)

After successful push:

1. **Verify deployment** (if CI/CD is configured):
   - Check CI pipeline status
   - Verify deployment succeeded

2. **Document the release**:
   - Tag with version if not auto-tagged
   - Update changelog if maintained manually

3. **If something goes wrong**:
   - Use `/rollback` command to safely revert
   - `/rollback commit <hash>` - Revert specific commit
   - `/rollback release <tag>` - Rollback to previous release

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

---

## Troubleshooting

**If push is blocked by validate-before-push.sh:**
- Check for uncommitted changes: `git status`
- Commit any remaining changes first

**If commit is blocked by enforce-commit-skill.sh:**
- Ensure you're using heredoc format for commit message
- Or use `/commit` command directly

**If something breaks after shipping:**
- Use `/rollback` command immediately
- Document what went wrong
- Fix and re-ship
