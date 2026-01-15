# Dependency Management

Manage project dependencies safely and thoroughly.

## Detect Package Manager

First, detect the project type:

```bash
# Check for package managers
ls -la package.json mix.exs Cargo.toml requirements.txt pyproject.toml go.mod 2>/dev/null || true
```

## Actions

Parse the user's intent to determine the action:

### 1. Audit: `/deps audit`

Check for security vulnerabilities.

**Node.js:**
```bash
npm audit
npm audit --json  # For detailed analysis
```

**Elixir:**
```bash
mix hex.audit
mix deps.audit
```

**Python:**
```bash
pip-audit  # If installed
safety check  # Alternative
```

**Rust:**
```bash
cargo audit
```

### 2. Outdated: `/deps outdated`

List packages that have newer versions.

**Node.js:**
```bash
npm outdated
```

**Elixir:**
```bash
mix hex.outdated
```

**Python:**
```bash
pip list --outdated
```

**Rust:**
```bash
cargo outdated
```

### 3. Update: `/deps update [package]`

Update dependencies safely.

**Safety rules:**
- Only update minor/patch versions by default
- Require explicit confirmation for major updates
- Run tests after updates
- Create a dedicated branch for updates

**Node.js:**
```bash
# Update all (minor/patch only)
npm update

# Update specific package
npm update [package]

# Update to latest (including major) - requires confirmation
npm install [package]@latest
```

**Elixir:**
```bash
mix deps.update --all  # All deps
mix deps.update [package]  # Specific dep
```

### 4. Clean: `/deps clean`

Remove unused dependencies.

**Node.js:**
```bash
# Find unused deps
npx depcheck

# Remove a specific unused dep
npm uninstall [package]
```

**Elixir:**
```bash
mix deps.clean --unused
```

### 5. Why: `/deps why [package]`

Explain why a package is installed.

**Node.js:**
```bash
npm explain [package]
# or
npm ls [package]
```

**Elixir:**
```bash
mix deps.tree | grep -A5 [package]
```

### 6. Add: `/deps add [package]`

Add a new dependency.

**Node.js:**
```bash
npm install [package]
# or for dev dependency
npm install --save-dev [package]
```

**Elixir:**
Add to mix.exs deps, then:
```bash
mix deps.get
```

## Post-Action Verification

After any dependency change:

1. **Run tests:**
   ```bash
   npm test  # or mix test, cargo test, etc.
   ```

2. **Check for type errors:**
   ```bash
   npm run typecheck  # if TypeScript
   ```

3. **Verify build:**
   ```bash
   npm run build
   ```

## Safety Guidelines

- **Never** auto-update major versions without explicit confirmation
- **Always** run tests after updates
- **Create branch** for significant updates: `git checkout -b deps/update-YYYY-MM-DD`
- **Review changelogs** for major updates
- **Check bundle size** impact for frontend packages
- **Verify license compatibility** for new packages

## Output Format

Provide a summary after each action:

```markdown
## Dependency Action: [Action Name]

### Changes Made
- [List of changes]

### Verification
- Tests: [Pass/Fail]
- Build: [Pass/Fail]
- Type Check: [Pass/Fail]

### Recommendations
- [Any follow-up actions needed]
```
