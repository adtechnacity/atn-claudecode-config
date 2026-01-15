# Performance Analysis

Profile, analyze, and optimize application performance.

## Analysis Modes

### 1. Frontend Performance: `/perf frontend`

Analyze web application performance.

**Using Chrome DevTools MCP:**
```
# Start performance trace
mcp__chrome-devtools__performance_start_trace with reload=true, autoStop=true

# After trace completes, analyze insights
mcp__chrome-devtools__performance_analyze_insight
```

**Key Metrics (Core Web Vitals):**
- **LCP** (Largest Contentful Paint) - Target: <2.5s
- **FID** (First Input Delay) - Target: <100ms
- **CLS** (Cumulative Layout Shift) - Target: <0.1
- **TTFB** (Time to First Byte) - Target: <800ms

**Bundle Analysis:**
```bash
# Analyze bundle size (Next.js)
npx @next/bundle-analyzer

# Analyze bundle (Vite)
npx vite-bundle-visualizer

# Generic webpack
npx webpack-bundle-analyzer stats.json
```

### 2. Backend Performance: `/perf backend`

Analyze server-side performance.

**For Node.js:**
```bash
# Profile with clinic
npx clinic doctor -- node server.js

# Memory profiling
node --inspect server.js
# Then use Chrome DevTools Memory tab
```

**For Elixir:**
```bash
# Observer
:observer.start()

# Benchee for benchmarking
mix run benchmark.exs
```

### 3. Database Performance: `/perf db`

Analyze database query performance.

**Identify slow queries:**
- Check query logs
- Look for N+1 patterns
- Analyze execution plans

```sql
EXPLAIN ANALYZE SELECT ...;
```

### 4. Specific Function: `/perf function [name]`

Profile a specific function.

**Approach:**
1. Add timing instrumentation
2. Run with representative data
3. Analyze results

```typescript
// Timing wrapper
console.time('functionName');
const result = await functionName(args);
console.timeEnd('functionName');
```

## Common Performance Issues

### React/Frontend
- [ ] **Unnecessary re-renders** - Missing memo/useMemo/useCallback
- [ ] **Large bundle** - Missing code splitting
- [ ] **Unoptimized images** - Missing lazy loading, wrong format
- [ ] **Blocking resources** - Render-blocking CSS/JS
- [ ] **Layout thrashing** - Forced synchronous layouts

### Backend
- [ ] **N+1 queries** - Missing eager loading
- [ ] **Missing indexes** - Slow database queries
- [ ] **Memory leaks** - Growing memory over time
- [ ] **Blocking operations** - Sync I/O in async context
- [ ] **Missing caching** - Repeated expensive operations

## Optimization Suggestions

After identifying issues, suggest:

### Quick Wins (Low effort, high impact)
- Add database indexes
- Enable caching
- Compress assets
- Lazy load images

### Medium Effort
- Implement memoization
- Add code splitting
- Optimize queries
- Add CDN

### Larger Refactors
- Restructure data fetching
- Implement pagination
- Add background jobs
- Database denormalization

## Output Format

```markdown
## Performance Analysis Report

### Overview
- **Scope:** [What was analyzed]
- **Duration:** [Analysis time]
- **Environment:** [Dev/Staging/Prod]

### Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| LCP | X.Xs | <2.5s | Pass/Fail |
| FID | Xms | <100ms | Pass/Fail |
| CLS | X.XX | <0.1 | Pass/Fail |

### Issues Found

#### Critical
1. [Issue] - [Impact] - [Suggested fix]

#### High Priority
2. [Issue] - [Impact] - [Suggested fix]

#### Medium Priority
3. [Issue] - [Impact] - [Suggested fix]

### Recommendations

1. **[Action]** - [Expected improvement]
2. **[Action]** - [Expected improvement]

### Before/After (if optimizations applied)
- [Metric]: [Before] → [After]
```

## Tools Integration

- **Chrome DevTools MCP** - Web performance traces
- **Explore Agent** - Find performance patterns in code
- **LSP** - Identify render triggers, dependency chains
