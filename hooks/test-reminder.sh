#!/bin/bash
set -uo pipefail

# Reminds about tests when committing changes to source files

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Only check on git commit
echo "$COMMAND" | grep -qE '^git commit' || exit 0

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null || echo "")

for FILE in $STAGED; do
  # Skip if file is itself a test
  if echo "$FILE" | grep -qE '\.(test|spec)\.(ts|tsx|js|jsx|py)$|_test\.(go|py)$|Test\.java$'; then
    continue
  fi

  # Check if it's a source file
  if echo "$FILE" | grep -qE '\.(ts|tsx|js|jsx|py|go|java)$'; then
    # Look for corresponding test file
    BASE="${FILE%.*}"
    EXT="${FILE##*.}"

    TEST_PATTERNS=(
      "${BASE}.test.${EXT}"
      "${BASE}.spec.${EXT}"
      "${BASE}_test.${EXT}"
      "$(dirname "$FILE")/__tests__/$(basename "$BASE").test.${EXT}"
    )

    FOUND_TEST=false
    for PATTERN in "${TEST_PATTERNS[@]}"; do
      if [ -f "$PATTERN" ]; then
        FOUND_TEST=true
        break
      fi
    done

    if [ "$FOUND_TEST" = false ]; then
      echo "NOTE: No test file found for $FILE" >&2
    fi
  fi
done

# Non-blocking - just informational
exit 0
