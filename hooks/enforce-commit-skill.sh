#!/bin/bash
# Hook to enforce using the /commit skill instead of raw git commit commands.
# Allows commits using heredoc format (indicates /commit workflow was followed).

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Check if it's a git commit command
if echo "$command" | grep -qE '\bgit\s+commit\b'; then
    # Allow if using --amend (for /commit workflow fixing pre-commit issues)
    if echo "$command" | grep -q -- '--amend'; then
        exit 0
    fi

    # Allow if using heredoc format (indicates /commit skill pattern)
    # Pattern: git commit -m "$(cat <<'EOF' or <<EOF
    if echo "$command" | grep -qE 'cat\s+<<'; then
        exit 0
    fi

    # Block direct commits
    cat <<'EOF'
{"decision":"block","reason":"Direct git commit is not allowed. Use the /commit skill instead to ensure:\n- Code simplification via code-simplifier agent\n- Comment auditing via code-reviewer agent\n- Proper validation (compile, test, lint)\n\nRun: /commit"}
EOF
    exit 2
fi

exit 0
