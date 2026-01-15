---
description: Prime Claude with project context. Run at session start for faster, more accurate responses.
---

# Project Context Primer

Load essential project context to understand the codebase quickly.

## Steps

1. **Read config files**: package.json, tsconfig.json, pyproject.toml, Cargo.toml, go.mod, .eslintrc*, .prettierrc*, biome.json, docker-compose.yml, Dockerfile

2. **Read docs**: README.md, CLAUDE.md, CONTRIBUTING.md, docs/architecture.md

3. **Map structure**: src/, lib/, app/, components/, pages/, api/ - identify entry points and main modules

4. **Identify stack**: Framework, Database, Testing, CI/CD

5. **Get version info**:
   ```bash
   git describe --tags --abbrev=0 2>/dev/null || echo "No tags"
   git tag --points-at HEAD
   git rev-list $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --count 2>/dev/null
   ```

6. **Summarize**: Project purpose, key directories, available scripts, testing approach, deployment method

## Output

- Tech stack
- Directory structure
- Key files
- Run/test/build commands
- Version status: current version, latest tag, commits since release, whether HEAD is tagged
