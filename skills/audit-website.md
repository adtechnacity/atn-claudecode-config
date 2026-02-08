---
name: audit-website
description: Audit websites for SEO, technical, content, performance and security issues using squirrelscan CLI. Use when the user asks to audit a website, check SEO, find broken links, or analyze site health.
---

# Website Audit

Audit websites for SEO, technical, content, performance and security issues using the squirrelscan CLI.

squirrelscan provides a CLI tool `squirrel` that performs extensive website auditing by emulating a browser and search crawler, analyzing structure and content against 230+ rules in 21 categories.

## Links

- squirrelscan: https://squirrelscan.com
- Documentation: https://docs.squirrelscan.com
- Rule lookup: `https://docs.squirrelscan.com/rules/{rule_category}/{rule_id}`

## Categories

SEO (meta tags, titles, canonical URLs, Open Graph), technical (broken links, redirects, page speed, mobile), performance (load time, resources, caching), content (headings, alt text, quality), security (leaked secrets, HTTPS, headers, mixed content), accessibility (contrast, keyboard nav), links (broken internal/external), E-E-A-T, mobile, crawlability, schema/structured data, legal compliance, social (OG, Twitter Cards), URL structure, keywords, images, local SEO, video.

## Prerequisites

Install if not available:

```bash
curl -fsSL https://squirrelscan.com/install | bash
```

Verify: `squirrel --version`

## Setup

Each project needs a `squirrel.toml`. Create with:

```bash
squirrel init -n <project-name>
```

The project name identifies the database. Stored in `~/.squirrel/projects/`.

## Usage

### Three Processes

- **crawl** — discover and fetch pages
- **analyze** — run audit rules on crawled pages
- **report** — generate output in desired format

The `audit` command wraps all three:

```bash
squirrel audit https://example.com --format llm
```

Always use `--format llm` for LLM-optimized output.

### Workflow

1. **First scan**: surface coverage (default, 100 pages) for quick overview
2. **Second scan**: full coverage for comprehensive analysis
3. **Fix → re-audit → fix** until scores reach target

### URL Discovery

If no URL provided:
1. Check local project for dev server, Vercel links, env vars, or code references
2. If multiple options found, prompt user to choose (suggest live over local)
3. If nothing found, ask user for URL

Prefer auditing **live websites** for true representation of performance and rendering.

### Coverage Modes

| Mode | Pages | Use Case |
|------|-------|----------|
| `quick` | 25 | CI checks, fast health check |
| `surface` | 100 | General audits (default) |
| `full` | 500 | Deep analysis, pre-launch |

```bash
squirrel audit https://example.com -C quick --format llm
squirrel audit https://example.com -C full --format llm
squirrel audit https://example.com -C surface -m 200 --format llm
```

### Common Options

| Option | Alias | Description |
|--------|-------|-------------|
| `--format <fmt>` | `-f` | console, text, json, html, markdown, llm |
| `--coverage <mode>` | `-C` | quick, surface, full |
| `--max-pages <n>` | `-m` | Max pages to crawl (max 5000) |
| `--refresh` | `-r` | Ignore cache, fresh crawl |
| `--resume` | | Resume interrupted crawl |
| `--verbose` | `-v` | Show progress |

### Reports and Diffs

```bash
# List recent audits
squirrel report --list

# Export specific audit
squirrel report <audit-id> --format llm

# Regression diff between audits
squirrel report --diff <audit-id> --format llm
squirrel report --regression-since example.com --format llm
```

## Fix Strategy

1. Fix **ALL** issues (errors, warnings, notices) — don't stop early
2. Parallelize fixes using subagents for bulk edits (alt text, headings, meta descriptions)
3. Iterate: fix batch → re-audit → fix remaining → repeat
4. Only pause for issues requiring human judgment (e.g., broken link review)
5. Show before/after score comparison when complete

### Score Targets

| Starting | Target | Work |
|----------|--------|------|
| < 50 | 75+ | Major fixes |
| 50-70 | 85+ | Moderate fixes |
| 70-85 | 90+ | Polish |
| > 85 | 95+ | Fine-tuning |

Site is complete when scores exceed 95 with full coverage.

### Fix Categories

| Category | Approach | Parallelizable |
|----------|----------|----------------|
| Meta tags/titles | Edit page components or metadata | No |
| Structured data | Add JSON-LD to templates | No |
| Image alt text | Edit content files | Yes |
| Heading hierarchy | Edit content files | Yes |
| Short descriptions | Edit frontmatter | Yes |
| HTTP→HTTPS links | Bulk replace in content | Yes |
| Broken links | Flag for user review | No |

For 5+ files needing the same fix, spawn subagents (3-5 files each).

Run typechecking and formatting after fixes if available in the environment.

## Output

On completion, provide a summary of all changes made.
