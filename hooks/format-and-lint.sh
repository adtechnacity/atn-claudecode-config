#!/bin/bash
# Claude Code Hook: Format and lint on save
# Type: PostToolUse (Edit, Write)
# Purpose: Auto-format files after edits, then report lint issues

# Don't use strict mode - formatting/linting should never block operations
set +e

# Parse JSON input from stdin (Claude Code hook protocol)
input=$(cat)
TOOL=$(echo "$input" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Only run for Edit and Write operations
if [[ "$TOOL" != "Edit" ]] && [[ "$TOOL" != "Write" ]]; then
    exit 0
fi

# Exit if no file path
if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# === PHASE 1: FORMAT ===

case "$EXT" in
    ts|tsx|js|jsx|mjs|cjs|json|css|scss|less|md|yaml|yml)
        # Find project root by walking up from the file's directory
        FILE_DIR=$(dirname "$FILE_PATH")
        PROJECT_ROOT=""
        SEARCH_DIR="$FILE_DIR"
        while [[ "$SEARCH_DIR" != "/" ]]; do
            if [[ -f "$SEARCH_DIR/package.json" ]]; then
                PROJECT_ROOT="$SEARCH_DIR"
                break
            fi
            SEARCH_DIR=$(dirname "$SEARCH_DIR")
        done
        if command -v npx &>/dev/null && [[ -n "$PROJECT_ROOT" ]]; then
            (cd "$PROJECT_ROOT" && npx prettier --write "$FILE_PATH" 2>/dev/null || true)
        fi
        ;;
    ex|exs)
        if command -v mix &>/dev/null; then
            mix format "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    rs)
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    go)
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    py)
        if command -v ruff &>/dev/null; then
            ruff format "$FILE_PATH" 2>/dev/null || true
        elif command -v black &>/dev/null; then
            black "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

# === PHASE 2: LINT (informational only) ===

case "$EXT" in
    ts|tsx|js|jsx)
        if command -v eslint &>/dev/null; then
            eslint "$FILE_PATH" --max-warnings 0 2>&1 || true
        fi
        ;;
    py)
        if command -v ruff &>/dev/null; then
            ruff check "$FILE_PATH" 2>&1 || true
        elif command -v flake8 &>/dev/null; then
            flake8 "$FILE_PATH" 2>&1 || true
        fi
        ;;
    go)
        if command -v golangci-lint &>/dev/null; then
            golangci-lint run "$FILE_PATH" 2>&1 || true
        fi
        ;;
esac

# Always exit successfully
exit 0
