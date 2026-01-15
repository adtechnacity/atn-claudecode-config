---
description: Audit codebase and update documentation for accuracy
---

Ensure documentation accurately reflects implementation.

## Integration

Used by `/ship` (Phase 1). Related: `/setup`, `/review`, `api-designer`, `schema-designer`

## Phase 1: Codebase Analysis

### 1.1 Read Documentation

Read completely: README.md, CLAUDE.md, specs (PRD, SPEC), API docs (OpenAPI, GraphQL)

Note claims, features, specs as baseline.

### 1.2 Map Implementation

Launch `feature-dev:code-explorer` (Task tool, `subagent_type: "feature-dev:code-explorer"`):

> "Map codebase architecture: (1) Core types/structures, (2) Entry points/flows, (3) External integrations/APIs, (4) Storage layer, (5) Key modules and responsibilities. Note interfaces, functions, behaviors."

## Phase 2: Gap Analysis

Compare findings against docs:

### 2.1 README Gaps
- Outdated description/features
- Incorrect install/usage instructions
- Features advertised but not implemented
- Missing dependencies

### 2.2 Memory File Gaps (CLAUDE.md)
- Missing/outdated functionality
- Incomplete sections
- Missing architectural patterns
- Constants not matching code

### 2.3 Specification Gaps
- Documented but not implemented
- Implemented but not documented
- Incorrect specs (thresholds, limits)

### 2.4 API Documentation Gaps
- Undocumented endpoints
- Outdated schemas
- Missing error codes
- Missing auth docs

Use `api-designer` for comprehensive API updates.

## Phase 3: Updates

- **README**: Match functionality, update instructions, verify features
- **Memory File**: Update architecture, complete lists, fix constants
- **Specs**: Flag gaps for product decision, update diffs
- **API Docs**: Use `api-designer`, document all endpoints

## Phase 4: Verification

### 4.1 Cross-Reference
- Docs match code
- No contradictions between files
- All paths exist

### 4.2 Summary
- Gaps found
- Updates made
- Unresolved items needing human decision

## Guidelines

- Code is source of truth when differing from docs
- Flag product decisions (don't assume intent)
- Keep docs concise but complete
- Preserve existing structure
- Use `/setup` for initial documentation
