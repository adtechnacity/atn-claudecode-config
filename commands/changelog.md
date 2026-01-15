---
description: Generate changelog from git history. Creates release notes from commits since last tag.
---

# Changelog Generator

Generate changelog from git commits. Integrates with `/ship`.

## Steps

### 1. Detect Version and Boundaries

**Auto-detect version:** Check package.json, mix.exs, Cargo.toml, or pyproject.toml.

**Find tag boundaries:**
```bash
git tag -l --sort=-version:refname | head -10  # Recent tags
git describe --tags --abbrev=0                  # Last tag
git log --oneline <from-tag>..<to-tag>          # Between tags
git log --oneline <last-tag>..HEAD              # Unreleased
```

### 2. Categorize Commits

By conventional commit type:
- `feat:` -> Features
- `fix:` -> Bug Fixes
- `perf:` -> Performance
- `docs:` -> Documentation
- `refactor:` -> Code Refactoring
- `test:` -> Tests
- `chore:` -> Maintenance
- `BREAKING CHANGE:` or `!:` -> Breaking Changes

### 3. Format Output

```markdown
## [version] - YYYY-MM-DD

### Breaking Changes
### Features
### Bug Fixes
### Performance
```

**Date:** Use tag date for releases, current date for unreleased, or `--date=YYYY-MM-DD` override.

### 4. Non-Conventional Commits

Group under "Other Changes".

### 5. Append to CHANGELOG.md (`--append`)

Insert new entry before first `## [` line. Preserve header. Create file if needed.

## Options

| Option | Description | Default |
|--------|-------------|---------|
| `--from=<tag>` | Start tag | previous tag |
| `--to=<tag>` | End tag | HEAD |
| `--unreleased` | Only unreleased changes | - |
| `--format=<md\|json>` | Output format | md |
| `--date=<YYYY-MM-DD>` | Override date | tag/today |
| `--append` | Prepend to CHANGELOG.md | - |
| `--version=<ver>` | Override version | auto-detect |

## Integration with /ship

After `/ship`: version tag becomes `--to` target. Use `--append` to auto-update CHANGELOG.md.
