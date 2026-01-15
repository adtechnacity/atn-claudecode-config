# Dead Code Cleanup

Find and safely remove unused code from the codebase.

## Targets for Cleanup

1. **Unused imports** - Imported but never used
2. **Unused exports** - Exported but never imported elsewhere
3. **Unused functions** - Defined but never called
4. **Unused variables** - Declared but never read
5. **Unreachable code** - Code after return/throw
6. **Commented-out code** - Old code left in comments
7. **Deprecated code** - Marked for removal

## Safety Protocol

**Before removing anything:**
1. Use LSP to verify no references exist
2. Search codebase for string references (dynamic imports)
3. Check if used in tests
4. Check if exported in public API

**Never remove:**
- Public API exports without deprecation period
- Code referenced by external packages
- Configuration used by build tools
- Files listed in .cleanupignore

## Workflow

### Step 1: Analysis

Use linting tools to find unused code:

**TypeScript/JavaScript:**
```bash
# ESLint no-unused-vars
npx eslint . --rule 'no-unused-vars: error' --format json

# TypeScript unused
npx tsc --noEmit 2>&1 | grep "declared but"

# Find unused exports
npx ts-unused-exports tsconfig.json
```

**Elixir:**
```bash
# Credo checks for unused
mix credo --strict
```

### Step 2: Categorize Findings

Group by risk level:

```markdown
### Safe to Remove (High Confidence)
- Unused local variables
- Unused private functions
- Unreachable code after return

### Review Before Removing (Medium Confidence)
- Unused exports (might be used externally)
- Unused parameters (might be for API compatibility)

### Keep for Now (Low Confidence)
- Potentially dynamic references
- Public API members
- Test utilities
```

### Step 3: Remove Systematically

**Approach:**
1. Start with highest confidence items
2. Make atomic commits per category
3. Run tests after each removal batch
4. Stop if tests fail

**For each removal:**
```bash
# Verify no references
rg "functionName" --type ts

# Check LSP references
# Use LSP findReferences tool

# Remove the code
# Run tests
npm test
```

### Step 4: Handle Commented Code

Find commented-out code blocks:

```bash
# Find large comment blocks that look like code
rg "^\s*//.*\{" --type ts  # JS/TS style
rg "^\s*#.*def\s" --type py  # Python style
```

**Decision tree for commented code:**
- Is it in git history? → Remove, can recover from git
- Is it a TODO/note? → Keep or convert to issue
- Is it alternate implementation? → Remove or document why kept

### Step 5: Verify Cleanup

After cleanup:
1. Run full test suite
2. Run type checker
3. Run linter
4. Build the project

```bash
npm run typecheck && npm run lint && npm test && npm run build
```

## Output Format

```markdown
## Cleanup Report

### Removed
- **Unused imports:** [count] across [files] files
- **Unused functions:** [count]
- **Unused variables:** [count]
- **Commented code:** [count] blocks
- **Lines removed:** [total]

### Kept (Needs Review)
- [item]: [reason kept]

### Verification
- Tests: Pass
- Types: Pass
- Build: Pass

### Commits Created
1. `chore: remove unused imports`
2. `chore: remove dead functions`
3. `chore: remove commented code`
```

## Options

- `/cleanup imports` - Only clean unused imports
- `/cleanup functions` - Only clean unused functions
- `/cleanup comments` - Only clean commented-out code
- `/cleanup --dry-run` - Report what would be removed without changes
