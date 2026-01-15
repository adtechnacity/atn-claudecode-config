# Dependency Management

Manage project dependencies safely.

## Detect Package Manager

```bash
ls -la package.json mix.exs Cargo.toml requirements.txt pyproject.toml go.mod 2>/dev/null || true
```

## Actions

### 1. Audit: `/deps audit`

Check for security vulnerabilities.

| Platform | Command |
|----------|---------|
| Node.js | `npm audit` or `npm audit --json` |
| Elixir | `mix hex.audit` / `mix deps.audit` |
| Python | `pip-audit` or `safety check` |
| Rust | `cargo audit` |

### 2. Outdated: `/deps outdated`

List packages with newer versions.

| Platform | Command |
|----------|---------|
| Node.js | `npm outdated` |
| Elixir | `mix hex.outdated` |
| Python | `pip list --outdated` |
| Rust | `cargo outdated` |

### 3. Update: `/deps update [package]`

**Safety rules:**
- Only minor/patch versions by default
- Require confirmation for major updates
- Run tests after updates
- Create dedicated branch: `git checkout -b deps/update-YYYY-MM-DD`

| Platform | Command |
|----------|---------|
| Node.js | `npm update [package]` (major: `npm install [package]@latest`) |
| Elixir | `mix deps.update [package]` or `--all` |

### 4. Clean: `/deps clean`

Remove unused dependencies.

| Platform | Command |
|----------|---------|
| Node.js | `npx depcheck` then `npm uninstall [package]` |
| Elixir | `mix deps.clean --unused` |

### 5. Why: `/deps why [package]`

Explain why a package is installed.

| Platform | Command |
|----------|---------|
| Node.js | `npm explain [package]` or `npm ls [package]` |
| Elixir | `mix deps.tree \| grep -A5 [package]` |

### 6. Add: `/deps add [package]`

| Platform | Command |
|----------|---------|
| Node.js | `npm install [package]` (dev: `--save-dev`) |
| Elixir | Add to mix.exs deps, then `mix deps.get` |

## Post-Action Verification

After any change:
1. Run tests (`npm test` / `mix test` / `cargo test`)
2. Type check if applicable (`npm run typecheck`)
3. Verify build (`npm run build`)

## Safety Guidelines

- **Never** auto-update major versions without confirmation
- **Always** run tests after updates
- **Review changelogs** for major updates
- **Check bundle size** for frontend packages
- **Verify license compatibility** for new packages

## Output Format

```markdown
## Dependency Action: [Action Name]

### Changes Made
- [List of changes]

### Verification
- Tests: [Pass/Fail]
- Build: [Pass/Fail]
- Type Check: [Pass/Fail]

### Recommendations
- [Follow-up actions needed]
```
