#!/bin/bash
set -euo pipefail

# Prevents direct commits/pushes to protected branches

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

PROTECTED_BRANCHES="main master production develop staging release"

# Check if this is a git commit or push command
if echo "$COMMAND" | grep -qE '\bgit\s+(commit|push)\b'; then
  # Allow tag-only pushes (e.g., git push origin v1.0.0, git push origin refs/tags/*)
  if echo "$COMMAND" | grep -qE '\bgit\s+push\b' && ! echo "$COMMAND" | grep -qE '\bgit\s+commit\b'; then
    if echo "$COMMAND" | grep -qE '\bgit\s+push\s+\S+\s+(v[0-9]|refs/tags/)'; then
      exit 0
    fi
  fi

  CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

  if [[ -z "$CURRENT_BRANCH" ]]; then
    exit 0  # Not on a named branch (detached HEAD or not a repo), nothing to protect
  fi

  for branch in $PROTECTED_BRANCHES; do
    if [ "$CURRENT_BRANCH" = "$branch" ]; then
      echo "BLOCKED: Cannot commit/push directly to '$branch' branch." >&2
      echo "Create a feature branch first: git checkout -b feature/your-feature" >&2
      exit 2
    fi
  done
fi

exit 0
