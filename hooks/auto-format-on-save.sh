#!/bin/bash
# Claude Code Hook: Auto-format on save
# Type: PostToolUse (Edit, Write)
# Purpose: Automatically format files after Claude edits them

# Don't use strict mode - formatting should never block operations
set +e

# Get file path and tool from environment
FILE_PATH="${CLAUDE_FILE_PATH:-}"
TOOL="${CLAUDE_TOOL:-}"

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

# Format based on file type
case "$EXT" in
    ts|tsx|js|jsx|mjs|cjs)
        # TypeScript/JavaScript - use prettier if available
        if command -v npx &>/dev/null && [[ -f "package.json" ]]; then
            npx prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    json)
        # JSON - use prettier
        if command -v npx &>/dev/null && [[ -f "package.json" ]]; then
            npx prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    ex|exs)
        # Elixir - use mix format
        if command -v mix &>/dev/null; then
            mix format "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    rs)
        # Rust - use rustfmt
        if command -v rustfmt &>/dev/null; then
            rustfmt "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    go)
        # Go - use gofmt
        if command -v gofmt &>/dev/null; then
            gofmt -w "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    py)
        # Python - use black or ruff if available
        if command -v ruff &>/dev/null; then
            ruff format "$FILE_PATH" 2>/dev/null || true
        elif command -v black &>/dev/null; then
            black "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    css|scss|less)
        # CSS - use prettier
        if command -v npx &>/dev/null && [[ -f "package.json" ]]; then
            npx prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    md)
        # Markdown - use prettier
        if command -v npx &>/dev/null && [[ -f "package.json" ]]; then
            npx prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
    yaml|yml)
        # YAML - use prettier
        if command -v npx &>/dev/null && [[ -f "package.json" ]]; then
            npx prettier --write "$FILE_PATH" 2>/dev/null || true
        fi
        ;;
esac

# Always exit successfully - formatting should never block operations
exit 0
