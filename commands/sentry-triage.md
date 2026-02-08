---
description: Triage Sentry errors across projects. Investigate, fix, ignore, or resolve issues.
argument-hint: Optional project name or issue URL
---

## Integration

Related: **`/debug`** (manual debugging), **`/audit-code`** (code quality)

MCP: **sentry** — issue tracking, analysis, triage, event search

## Phase 1: Discovery

### 1.1 Identify Organization and Projects

```
mcp__sentry__find_organizations()
mcp__sentry__find_projects(organizationSlug)
```

If a project or issue URL is provided, scope to that. Otherwise, scan all projects.

### 1.2 Fetch Unresolved Issues

For each project, search for unresolved issues sorted by frequency/impact:

```
mcp__sentry__search_issues(
  organizationSlug,
  projectSlugOrId,
  naturalLanguageQuery: "unresolved errors sorted by frequency"
)
```

Also check for recent regressions:

```
mcp__sentry__search_issues(
  organizationSlug,
  naturalLanguageQuery: "regressed issues from last 7 days"
)
```

### 1.3 Present Overview

Summarize: total unresolved count per project, highest-impact issues, any regressions.

---

## Phase 2: Categorize Issues

For each issue, get details and classify:

```
mcp__sentry__get_issue_details(organizationSlug, issueId)
```

### Categories

| Category | Criteria | Action |
|----------|----------|--------|
| **Noise** | Browser extensions, bots, crawlers, ad blockers, network errors from client | Ignore in Sentry |
| **Third-party** | Errors in vendor scripts, CDN failures, external API timeouts | Ignore or monitor |
| **Valid bug** | Errors in our code with reproducible stack traces | Investigate and fix |
| **Edge case** | Rare conditions, unsupported browsers, malformed input | Assess impact, fix or ignore |
| **Regression** | Previously resolved issues that recurred | Priority fix |

### Noise Patterns to Auto-Ignore

- Browser extension errors (`chrome-extension://`, `moz-extension://`)
- `ResizeObserver loop` errors
- `Non-Error promise rejection` from third-party scripts
- Network errors without user impact (`ERR_NETWORK`, `ERR_INTERNET_DISCONNECTED`)
- Bot/crawler user agents
- `Script error.` with no stack trace (cross-origin)

**ASK USER**: Present the categorized list and get approval for ignore candidates.

---

## Phase 3: Investigate Valid Bugs

For each valid bug (highest impact first):

### 3.1 Deep Analysis

```
mcp__sentry__get_issue_details(organizationSlug, issueId)
mcp__sentry__analyze_issue_with_seer(organizationSlug, issueId)
```

Review: stack trace, breadcrumbs, affected users count, frequency, environments.

### 3.2 Search Related Events

```
mcp__sentry__search_issue_events(
  issueId,
  organizationSlug,
  naturalLanguageQuery: "from last 7 days in production"
)
```

Look for patterns: specific browsers, user segments, request paths, time patterns.

### 3.3 Trace Through Code

Launch agents via Task tool (`subagent_type: "Explore"`) or read files directly to trace the root cause from the stack trace. Identify:
- The failing line and why it fails
- Edge cases not handled
- Missing validation or error boundaries

### 3.4 Ask Questions

Before implementing fixes, ask the user about:
- Expected behavior for edge cases
- Whether the error path should fail silently or show an error
- Priority relative to other work

---

## Phase 4: Implement Fixes

For each approved fix:

1. Implement the minimal fix
2. Add error handling for the edge case
3. Write a regression test if applicable
4. Run validation (typecheck, lint, test)

---

## Phase 5: Update Sentry

### 5.1 Ignore Noise Issues

For each approved noise issue:

```
mcp__sentry__update_issue(
  organizationSlug,
  issueId,
  status: "ignored"
)
```

### 5.2 Resolve Fixed Issues

For each fixed issue:

```
mcp__sentry__update_issue(
  organizationSlug,
  issueId,
  status: "resolved"
)
```

### 5.3 Suggest Inbound Filters

If recurring noise patterns are found, recommend Sentry inbound filters or `beforeSend` rules to prevent them from being captured:

```javascript
Sentry.init({
  beforeSend(event) {
    // Filter browser extension errors
    const frames = event.exception?.values?.[0]?.stacktrace?.frames ?? [];
    if (frames.some(f => f.filename?.includes('extension://'))) return null;
    return event;
  },
});
```

---

## Phase 6: Report

```markdown
## Sentry Triage Report

**Projects Scanned**: [list]
**Date**: [date]

### Issues Resolved (Fixed)
| Issue | Project | Impact | Root Cause | Fix |
|-------|---------|--------|------------|-----|

### Issues Ignored (Noise)
| Issue | Project | Reason |
|-------|---------|--------|

### Issues Deferred
| Issue | Project | Reason | Suggested Action |
|-------|---------|--------|------------------|

### Suggested Inbound Filters
- [Filter description and implementation]

### Remaining Unresolved
- [count] issues across [projects] — next triage recommended in [timeframe]
```

## Options

- `/sentry-triage` - Full triage across all projects
- `/sentry-triage <project>` - Triage a specific project
- `/sentry-triage <issue-url>` - Investigate a specific issue
