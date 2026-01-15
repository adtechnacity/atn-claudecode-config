#!/bin/bash
# Hook: enforce-commit-skill.sh
# Type: PreToolUse (Bash)
# Purpose: Enforce using the /commit skill instead of raw git commit commands
#
# This hook ensures code quality by requiring the /commit workflow which includes:
# - Code simplification via code-simplifier agent
# - Comment auditing via code-reviewer agent
# - Full validation (typecheck, lint, test, build)
# - Security checks via security-scanner patterns
#
# Related hooks that also run during commit workflow:
# - prevent-secrets-edit.sh: Blocks edits to sensitive files
# - auto-format-on-save.sh: Auto-formats files after edits
# - validate-before-push.sh: Validates before git push (if pushing after commit)
#
# Related agents:
# - git-commit-validator: Handles the full commit validation process
# - security-scanner: For comprehensive security audits
#
# Next steps after /commit:
# - git push: Push directly to remote
# - /pr: Create a pull request (optional)
# - /ship: Full production release workflow

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
