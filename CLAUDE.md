# User Tools & Integrations

## MCP Servers

The following MCP servers are available for interacting with external services:

- **analytics-mcp** - Google Analytics reporting
- **aws** - AWS prompt understanding
- **aws-cloudwatch** - CloudWatch logs, metrics, alarms
- **chrome-devtools** - Browser debugging including browser extensions
- **cloudflare** - DNS, Workers, R2, D1, KV, Queues, Domain Registration
- **context7** - Library and API documentation lookup
- **google-tag-manager-mcp-server** - Google Tag Manager
- **growthbook** - Feature flags and A/B testing
- **sentry** - Error tracking and monitoring
- **snowflake** - Data warehouse queries in Snowflake

## Error Investigation with Sentry

When investigating errors, bugs, or production issues, **always use Sentry first**:

1. **Search for issues**: Use `mcp__sentry__search_issues` to find relevant errors
2. **Get issue details**: Use `mcp__sentry__get_issue_details` for stack traces and context
3. **Analyze with AI**: Use `mcp__sentry__analyze_issue_with_seer` for root cause analysis
4. **Search events**: Use `mcp__sentry__search_events` to find related occurrences
5. **Trace requests**: Use `mcp__sentry__get_trace_details` for distributed tracing

**When to use Sentry:**
- User reports a bug or error
- Investigating production failures
- Debugging API errors or 500s
- Looking for patterns in recurring issues
- Understanding error frequency and impact

**Typical workflow:**
1. Search issues for keywords or error messages
2. Get details on the most relevant issue
3. Review stack trace and breadcrumbs
4. Check related events for patterns
5. Use Seer analysis for complex issues

## CLI Tools

The following CLI tools are installed and available via Bash:

- **vercel** - Vercel deployments and project management
- **gh** - GitHub CLI for repos, PRs, issues, releases
- **psql** - PostgreSQL database client

---

## Coding Conventions

### TypeScript/React
- Prefer `const` over `let`; never use `var`
- Use named exports over default exports
- Prefer `interface` over `type` for object shapes
- Use discriminated unions for state variants
- Avoid `any` - use `unknown` and narrow with type guards
- Use `satisfies` for type validation without widening
- Prefer early returns over nested conditionals
- Destructure props in function signature

### React Patterns
- Functional components only (no class components)
- Custom hooks for shared logic (`use` prefix)
- Colocate state as close to usage as possible
- Prefer server components by default (Next.js)
- Use `Suspense` + `ErrorBoundary` for async boundaries

### Node.js / API
- Always handle async errors with try/catch or .catch()
- Validate input at API boundaries (zod, etc.)
- Use structured logging (JSON format)
- Never log sensitive data (tokens, passwords, PII)

### Testing
- Tests live next to source files (`*.test.ts` / `*.spec.ts`)
- Prefer `vitest` or project-configured runner
- Test behavior, not implementation details
- Use `describe`/`it` with clear descriptions
- Always enforce Test Driven Development

### Git Workflow
- Use conventional commits: `feat:`, `fix:`, `update:`, `docs:`, `test:`, `chore:`
- Always use `/commit` (not raw `git commit`) - enforced by hook
- Branch naming: `<type>/<short-description>` (kebab-case)
- Never force-push to main/master/production
- Full release flow: `/commit` -> `/pr` -> `/ship`

### General Rules
- Keep functions under 50 lines
- Max 3 levels of nesting
- No magic numbers - use named constants
- Handle errors at the appropriate boundary
- Prefer composition over inheritance
