---
description: Audit codebase and update documentation for accuracy
---

Audit the codebase to ensure documentation accurately reflects the implementation.

## Integration

This command is used by:
- **`/ship`** (Phase 1) - Mandatory docs audit before production release

Related commands:
- **`/setup`** - Creates initial CLAUDE.md and project documentation
- **`/review`** - May identify documentation gaps during code review

Related skills:
- **`api-designer`** - For API documentation (OpenAPI, GraphQL SDL)
- **`schema-designer`** - For database schema documentation

## Agent Integration

| Agent | Phase | Purpose |
|-------|-------|---------|
| `feature-dev:code-explorer` | Codebase Analysis | Map architecture faster than manual file reading |

Spawn via Task tool with `subagent_type` set to `feature-dev:code-explorer`.

## Phase 1: Codebase Analysis

### 1.1 Read Existing Documentation

Manually read project documentation completely:
- README.md (or equivalent)
- CLAUDE.md or other project memory files (may have been created by `/setup`)
- Specification documents (PRD, SPEC, etc.)
- API documentation (OpenAPI specs, GraphQL schemas)

Note current claims, features, and specifications as baseline for gap analysis.

### 1.2 Map Implementation with Code Explorer

Launch `feature-dev:code-explorer` with prompt:
> "Map the architecture of this codebase. Document: (1) Core types and data structures, (2) Entry points and main flows, (3) External integrations and APIs, (4) Storage/persistence layer, (5) Key modules and their responsibilities. For each area, note key interfaces, functions, and behaviors."

## Phase 2: Gap Analysis

Compare agent findings against documentation:

### 2.1 README Gaps
- Outdated project description or features
- Incorrect installation/usage instructions
- Features advertised but not implemented
- Missing dependencies or requirements

### 2.2 Memory File Gaps (CLAUDE.md or similar)
- Missing or outdated functionality
- Incomplete sections (partial lists, missing details)
- Missing architectural patterns or conventions
- Constants/limits that don't match code

### 2.3 Specification Gaps
- Features documented but not implemented
- Features implemented but not documented
- Incorrect specifications (wrong thresholds, limits)

### 2.4 API Documentation Gaps
- Endpoints not documented
- Request/response schemas outdated
- Missing error code documentation
- Authentication/authorization not documented

**Tip:** Use `api-designer` skill for comprehensive API documentation updates.

## Phase 3: Documentation Updates

### 3.1 Update README
- Ensure description matches current functionality
- Update installation and usage instructions
- Verify listed features are implemented
- Add any missing requirements

### 3.2 Update Memory File
- Ensure architecture reflects actual file structure
- Complete partial lists (types, functions, patterns)
- Update constants to match code
- Add missing patterns or conventions

### 3.3 Update Specifications (if needed)
- Flag implementation gaps for product decision
- Update specifications that differ from code

### 3.4 Update API Documentation
- Use `api-designer` skill for OpenAPI/GraphQL updates
- Ensure all endpoints are documented
- Update request/response examples

## Phase 4: Verification

### 4.1 Cross-Reference Check
- Verify docs match the code
- Ensure no contradictions between doc files
- Confirm all file paths mentioned exist

### 4.2 Summary Report
- Documentation gaps found
- Updates made
- Unresolved discrepancies requiring human decision

## Guidelines

- When code differs from documentation, code is source of truth
- Flag product decisions needed (don't assume intent)
- Keep documentation concise but complete
- Preserve existing structure where possible
- For new projects, `/setup` command creates initial documentation structure
