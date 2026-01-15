# Performance Analysis

Profile, analyze, and optimize application performance.

## Analysis Modes

### 1. Frontend: `/perf frontend`

**Chrome DevTools MCP:**
```
mcp__chrome-devtools__performance_start_trace (reload=true, autoStop=true)
mcp__chrome-devtools__performance_analyze_insight
```

**Core Web Vitals:**
- LCP < 2.5s
- FID < 100ms
- CLS < 0.1
- TTFB < 800ms

**Bundle Analysis:** `npx @next/bundle-analyzer` | `npx vite-bundle-visualizer` | `npx webpack-bundle-analyzer stats.json`

### 2. Backend: `/perf backend`

**Node.js:** `npx clinic doctor -- node server.js`
**Elixir:** `:observer.start()` or Benchee

### 3. Database: `/perf db`

Check query logs, N+1 patterns, execution plans: `EXPLAIN ANALYZE SELECT ...;`

### 4. Function: `/perf function [name]`

Add timing, run with representative data, analyze.

## Common Issues

**Frontend:**
- Unnecessary re-renders (missing memo/useMemo/useCallback)
- Large bundles (missing code splitting)
- Unoptimized images
- Blocking resources
- Layout thrashing

**Backend:**
- N+1 queries
- Missing indexes
- Memory leaks
- Blocking I/O
- Missing caching

## Optimization Priority

**Quick wins:** indexes, caching, compression, lazy loading
**Medium:** memoization, code splitting, query optimization, CDN
**Large:** data fetching restructure, pagination, background jobs, denormalization

## Output Format

```markdown
## Performance Analysis Report

### Overview
Scope | Duration | Environment

### Metrics
| Metric | Current | Target | Status |

### Issues Found
#### Critical/High/Medium
[Issue] - [Impact] - [Fix]

### Recommendations
[Action] - [Expected improvement]
```

## Tools
Chrome DevTools MCP, Explore Agent, LSP
