#!/bin/bash
# Claude Code Hook: Validate before git push
# Type: PreToolUse (Bash)
# Purpose: Safety checks before pushing to remote

set -euo pipefail

# Parse JSON input from stdin (Claude Code hook protocol)
input=$(cat)
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only check git push commands
if [[ "$COMMAND" != *"git push"* ]]; then
    exit 0
fi

# Check for uncommitted changes
if [[ -n $(git status --porcelain 2>/dev/null || true) ]]; then
    echo "WARNING: Uncommitted changes detected."
    echo ""
    echo "You have changes that haven't been committed yet."
    echo "Consider using /commit before pushing."
    echo ""
    # Don't block, just warn
fi

# Check if we're on a protected branch
CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "")
PROTECTED_BRANCHES=("main" "master" "production" "develop" "staging" "release")

for branch in "${PROTECTED_BRANCHES[@]}"; do
    if [[ "$CURRENT_BRANCH" == "$branch" ]]; then
        # Check for force push
        if (echo "$COMMAND" | grep -qE '(\s|^)--force(\s|$)' || echo "$COMMAND" | grep -qE '(\s)-f(\s|$)') && ! echo "$COMMAND" | grep -q -- '--force-with-lease'; then
            echo "BLOCKED: Force push to protected branch '$branch' is not allowed."
            echo ""
            echo "Force pushing to $branch can cause data loss and break CI/CD."
            echo "If this is intentional, push manually outside Claude Code."
            exit 2
        fi
    fi
done

# Reminder about /ship workflow for production releases
if [[ "$CURRENT_BRANCH" == "main" ]] || [[ "$CURRENT_BRANCH" == "master" ]]; then
    echo "REMINDER: You're pushing to '$CURRENT_BRANCH'."
    echo "Consider using /ship for production releases with full validation."
    echo ""
fi

# Allow the operation
exit 0
