#!/bin/bash
# Claude Code Hook: Notify on completion
# Type: PostToolUse (Bash)
# Purpose: Send desktop notification when long-running commands complete

# Don't use strict mode for notifications - we want this to always succeed silently
set +e

# Get command and exit code from environment
COMMAND="${CLAUDE_COMMAND:-}"
EXIT_CODE="${CLAUDE_EXIT_CODE:-0}"

# Commands that warrant a notification
LONG_RUNNING_PATTERNS=(
    "npm test"
    "npm run test"
    "npm run build"
    "npm run typecheck"
    "npm run lint"
    "npm install"
    "npm ci"
    "mix test"
    "mix compile"
    "mix deps.get"
    "mix phx.server"
    "cargo build"
    "cargo test"
    "docker build"
    "pulumi preview"
    "pulumi up"
)

# Check if command matches any long-running pattern
should_notify=false
matched_command=""

for pattern in "${LONG_RUNNING_PATTERNS[@]}"; do
    if [[ "$COMMAND" == *"$pattern"* ]]; then
        should_notify=true
        matched_command="$pattern"
        break
    fi
done

# Send notification if applicable (macOS only)
if [[ "$should_notify" == true ]] && command -v osascript &>/dev/null; then
    if [[ "$EXIT_CODE" == "0" ]]; then
        status="completed successfully"
        sound="Glass"
    else
        status="failed (exit code: $EXIT_CODE)"
        sound="Basso"
    fi

    osascript -e "display notification \"$matched_command $status\" with title \"Claude Code\" sound name \"$sound\"" 2>/dev/null || true
fi

# Always exit successfully - notifications should never block operations
exit 0
