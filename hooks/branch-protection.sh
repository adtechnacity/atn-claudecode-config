#!/bin/bash
set -euo pipefail

# Prevents direct commits/pushes to protected branches

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

PROTECTED_BRANCHES="main master production develop"

# Check if this is a git commit or push command
if echo "$COMMAND" | grep -qE '^git (commit|push)'; then
  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

  for branch in $PROTECTED_BRANCHES; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
      echo "BLOCKED: Cannot commit/push directly to '$branch' branch." >&2
      echo "Create a feature branch first: git checkout -b feature/your-feature" >&2
      exit 2
    fi
  done
fi

exit 0
