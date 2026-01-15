#!/bin/bash
set -uo pipefail

# Checks for vulnerabilities when installing dependencies

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Check if this is a dependency install command
if echo "$COMMAND" | grep -qE '^(npm|yarn|pnpm) (install|add|i)'; then
  echo "Running security audit on dependencies..." >&2

  # npm audit (non-blocking)
  if command -v npm &> /dev/null && [ -f "package.json" ]; then
    npm audit --audit-level=high 2>&1 | head -20 || true
  fi
fi

# pip install
if echo "$COMMAND" | grep -qE '^pip install'; then
  if command -v pip-audit &> /dev/null; then
    pip-audit 2>&1 | head -20 || true
  fi
fi

# Always allow - just informational
exit 0
