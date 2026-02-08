---
description: Audit and manage project dependencies
---

Check dependencies for outdated packages, security vulnerabilities, and unused modules.

## Integration

Used by: **`/audit-code`** (Phase 1.2), **`/audit-all`** (via `/audit-code`)

Related: **`/audit-code`**, **`/commit`**, **`/ship`**

Hook: **`dependency-check.sh`** runs security audit on `npm install`

## Build System Detection

| Indicator | Outdated | Audit | Unused |
|-----------|----------|-------|--------|
| `package.json` | `npm outdated` | `npm audit` | `npx depcheck` |
| `mix.exs` | `mix hex.outdated` | `mix deps.audit` | N/A |
| `Cargo.toml` | `cargo outdated` | `cargo audit` | `cargo udeps` |
| `pyproject.toml` | `pip list --outdated` | `pip-audit` | N/A |

Skip unavailable commands.

## Phase 1: Security Audit

```bash
# npm
npm audit --audit-level=moderate

# Fix automatically where possible
npm audit fix
```

Flag: critical/high vulnerabilities, known CVEs, compromised packages.

## Phase 2: Outdated Check

```bash
npm outdated
```

Categorize updates:
- **Patch** (x.x.PATCH): Safe to update
- **Minor** (x.MINOR.0): Usually safe, check changelog
- **Major** (MAJOR.0.0): Breaking changes, needs review

## Phase 3: Unused Dependencies

```bash
npx depcheck
```

Check results against:
- Build config imports (webpack, vite, etc.)
- CLI tools used in scripts
- Peer dependencies
- Type packages (`@types/*`)

## Phase 4: Apply Updates

### Safe updates (patch + minor):
```bash
npm update
```

### Major updates (one at a time):
```bash
npm install <package>@latest
npm run typecheck && npm test
```

## Phase 5: Report

```markdown
## Dependency Report

### Security
- Critical: [count]
- High: [count]
- Fixed: [count]
- Needs manual fix: [details]

### Updates Applied
| Package | From | To | Type |
|---------|------|----|------|

### Updates Deferred (Major)
| Package | Current | Latest | Breaking Changes |
|---------|---------|--------|------------------|

### Unused Dependencies
- [package]: [safe to remove / used by build tool]

### Verification
- Tests: Pass/Fail
- Types: Pass/Fail
- Build: Pass/Fail
```

## Options

- `/audit-deps` - Full audit (security + outdated + unused)
- `/audit-deps audit` - Security audit only
- `/audit-deps outdated` - Check for outdated only
- `/audit-deps unused` - Find unused dependencies only
- `/audit-deps update` - Apply safe updates (patch + minor)
