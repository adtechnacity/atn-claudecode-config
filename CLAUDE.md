# User Tools & Integrations

## MCP Servers

The following MCP servers are available for interacting with external services:

- **analytics-mcp** - Google Analytics reporting
- **aws** - AWS prompt understanding
- **aws-cloudwatch** - CloudWatch logs, metrics, alarms
- **klaviyo** - Email marketing automation: profiles, events, campaigns, flows, segments, templates, reporting
- **chrome-devtools** - Browser debugging including browser extensions
- **cloudflare** - Workers, R2, D1, KV, Queues, Workflows, Cron, Secrets, Env vars
- **cloudflare-dns** - DNS record management (create, list, update, delete records and zones)
- **context7** - Library and API documentation lookup
- **growthbook** - Feature flags and A/B testing
- **gtm** - Google Tag Manager (accounts, containers, variables, GA4/Facebook pixel setup)
- **sentry** - Error tracking and monitoring
- **snowflake** - Data warehouse queries (SQL via Snowflake)

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

## Email Marketing with Klaviyo

Use the Klaviyo MCP for managing email marketing, customer profiles, and automation.

**Tools by category:**

| Category          | Tools                                                                                     | Purpose                         |
| ----------------- | ----------------------------------------------------------------------------------------- | ------------------------------- |
| **Profiles**      | `get_profiles`, `get_profile`, `create_profile`, `update_profile`                         | Manage customer data            |
| **Subscriptions** | `subscribe_profile_to_marketing`, `unsubscribe_profile_from_marketing`                    | Manage opt-in/out               |
| **Events**        | `get_events`, `create_event`, `get_metrics`, `get_metric`                                 | Track and query customer events |
| **Campaigns**     | `get_campaigns`, `get_campaign`, `create_campaign`, `assign_template_to_campaign_message` | Email campaigns                 |
| **Flows**         | `get_flows`, `get_flow`                                                                   | Automation flows                |
| **Segments**      | `get_segments`, `get_segment`, `get_lists`, `get_list`                                    | Audience targeting              |
| **Templates**     | `get_email_template`, `create_email_template`                                             | Email HTML templates            |
| **Reporting**     | `get_campaign_report`, `get_flow_report`                                                  | Performance analytics           |
| **Other**         | `get_account_details`, `get_catalog_items`, `upload_image_from_url`                       | Account, catalog, images        |

**Common workflows:**

1. **Look up a customer**: `get_profiles` filtered by email, then `get_events` for their activity
2. **Check campaign performance**: `get_campaigns` to find it, then `get_campaign_report` for metrics
3. **Review automation**: `get_flows` to list flows, `get_flow` + `get_flow_report` for details
4. **Create a campaign**: `create_email_template` -> `create_campaign` -> `assign_template_to_campaign_message`
5. **Track a custom event**: `create_event` with metric name and profile identifier

**Note:** Klaviyo handles marketing automation (flows, campaigns, segmentation). Transactional emails (order confirmations, delivery notifications) are sent via **Resend**.

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
