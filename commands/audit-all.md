---
description: Run all audits (code, tests, docs, comments) sequentially
---

Run comprehensive audit of the entire codebase.

**Execute all phases sequentially. Fix Critical/High issues before proceeding.**

## Integration

Combines: `/audit-code`, `/audit-tests`, `/audit-docs`, `/audit-comments`

Used by: `/ship` can use this instead of running individual audits

## Phase 1: Code Audit

Run `/audit-code` to completion.

**Focus**: Security, performance, maintainability, reliability

**Gate**: Fix all Critical/High issues before Phase 2.

---

## Phase 2: Test Audit

Run `/audit-tests` to completion.

**Focus**: Coverage gaps, redundant tests, test quality

**Gate**: All tests must pass before Phase 3.

---

## Phase 3: Docs Audit

Run `/audit-docs` to completion.

**Focus**: README, CLAUDE.md, API docs, specs accuracy

**Gate**: Fix documentation discrepancies before Phase 4.

---

## Phase 4: Comments Audit

Run `/audit-comments` to completion.

**Focus**: Remove redundant comments, add missing explanations

---

## Summary Report

After all phases complete, provide:

| Audit | Issues Found | Fixed | Deferred |
|-------|--------------|-------|----------|
| Code | - | - | - |
| Tests | - | - | - |
| Docs | - | - | - |
| Comments | - | - | - |

**Build Status**: Pass/Fail

**Recommended Follow-ups**: `/cleanup`, `/perf`, `/deps`
