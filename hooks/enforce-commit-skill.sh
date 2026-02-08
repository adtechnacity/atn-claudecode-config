#!/bin/bash
# PreToolUse (Bash) hook: Blocks raw `git commit` — use /commit instead.
# The /commit workflow runs validation, security checks, and formatting.
# See commit.md for full details.

set -euo pipefail

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // empty')

# Only check git commit commands
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

    # Block direct commits with helpful guidance
    cat <<'EOF'
{"decision":"block","reason":"Direct git commit is not allowed.\n\nUse /commit to ensure quality checks:\n- Code simplification (code-simplifier agent)\n- Comment auditing (code-reviewer agent)\n- Validation (typecheck, lint, test, build)\n- Security scanning\n\nRun: /commit\n\nAfter committing:\n- git push (push to remote)\n- /pr (create pull request - optional)\n- /ship (full production release)"}
EOF
    exit 2
fi

exit 0
