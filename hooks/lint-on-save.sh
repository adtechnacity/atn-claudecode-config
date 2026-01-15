#!/bin/bash
set -uo pipefail

# Runs linting after file edits (non-blocking, just reports)

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# Get file extension
EXT="${FILE_PATH##*.}"

# Run appropriate linter based on extension
case "$EXT" in
  ts|tsx|js|jsx)
    if command -v eslint &> /dev/null; then
      eslint "$FILE_PATH" --max-warnings 0 2>&1 || true
    fi
    ;;
  py)
    if command -v ruff &> /dev/null; then
      ruff check "$FILE_PATH" 2>&1 || true
    elif command -v flake8 &> /dev/null; then
      flake8 "$FILE_PATH" 2>&1 || true
    fi
    ;;
  go)
    if command -v golangci-lint &> /dev/null; then
      golangci-lint run "$FILE_PATH" 2>&1 || true
    fi
    ;;
esac

# Always succeed - linting is informational
exit 0
