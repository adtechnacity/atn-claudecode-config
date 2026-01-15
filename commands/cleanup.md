# Dead Code Cleanup

Find and safely remove unused code.

## Targets

1. Unused imports, exports, functions, variables
2. Unreachable code (after return/throw)
3. Commented-out code
4. Deprecated code

## Safety Protocol

**Before removing:**
1. LSP verify no references
2. Search for string references (dynamic imports)
3. Check test usage
4. Check public API exports

**Never remove:**
- Public API exports without deprecation
- Externally referenced code
- Build tool configurations
- Files in .cleanupignore

## Workflow

### Step 1: Analysis

**TypeScript/JavaScript:**
```bash
npx eslint . --rule 'no-unused-vars: error' --format json
npx tsc --noEmit 2>&1 | grep "declared but"
npx ts-unused-exports tsconfig.json
```

**Elixir:**
```bash
mix credo --strict
```

### Step 2: Categorize

**Safe (High Confidence):** Unused locals, private functions, unreachable code

**Review First (Medium):** Unused exports, unused parameters

**Keep (Low):** Dynamic references, public API, test utilities

### Step 3: Remove Systematically

1. Start with highest confidence
2. Atomic commits per category
3. Test after each batch
4. Stop if tests fail

```bash
rg "functionName" --type ts
npm test
```

### Step 4: Commented Code

```bash
rg "^\s*//.*\{" --type ts
rg "^\s*#.*def\s" --type py
```

**Decision:** In git history? Remove. TODO/note? Keep or create issue. Alternate implementation? Remove or document.

### Step 5: Verify

```bash
npm run typecheck && npm run lint && npm test && npm run build
```

## Output Format

```markdown
## Cleanup Report

### Removed
- Unused imports: [count] in [files] files
- Unused functions: [count]
- Unused variables: [count]
- Commented code: [count] blocks
- Lines removed: [total]

### Kept (Needs Review)
- [item]: [reason]

### Verification
- Tests: Pass
- Types: Pass
- Build: Pass

### Commits
1. `chore: remove unused imports`
2. `chore: remove dead functions`
3. `chore: remove commented code`
```

## Options

- `/cleanup imports` - Only imports
- `/cleanup functions` - Only functions
- `/cleanup comments` - Only commented code
- `/cleanup --dry-run` - Report without changes
