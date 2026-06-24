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

FILE_DIR=$(dirname "$FILE_PATH")

# Nearest node_modules/.bin/$1 walking up from the file. Finds binaries hoisted
# to a monorepo root or shared by a git worktree (the worktree itself has no
# node_modules, but its parent checkout does).
find_local_bin() {
    local name="$1" d="$FILE_DIR"
    while [[ -n "$d" && "$d" != "/" ]]; do
        [[ -x "$d/node_modules/.bin/$name" ]] && { printf '%s\n' "$d/node_modules/.bin/$name"; return 0; }
        d=$(dirname "$d")
    done
    return 1
}

# Nearest ancestor dir containing $1 (prints the dir, empty + nonzero if none).
find_up() {
    local name="$1" d="$FILE_DIR"
    while [[ -n "$d" && "$d" != "/" ]]; do
        [[ -e "$d/$name" ]] && { printf '%s\n' "$d"; return 0; }
        d=$(dirname "$d")
    done
    return 1
}

case "$EXT" in
    ts|tsx|js|jsx|mjs|cjs|json|css|scss|less|md|yaml|yml)
        # Respect the project's declared formatter. prettier ignores oxfmt/biome/
        # dprint configs (e.g. oxfmt printWidth 100 vs prettier's default 80) and
        # would reflow the whole file against CI, so prettier runs only when the
        # project picks it or declares no formatter at all. When a non-prettier
        # formatter is declared but its binary is absent, skip rather than corrupt.
        if oxroot=$(find_up .oxfmtrc.jsonc || find_up .oxfmtrc.json); then
            bin=$(find_local_bin oxfmt) && (cd "$oxroot" && "$bin" --write "$FILE_PATH" 2>/dev/null || true)
        elif bioroot=$(find_up biome.json || find_up biome.jsonc); then
            bin=$(find_local_bin biome) && (cd "$bioroot" && "$bin" format --write "$FILE_PATH" 2>/dev/null || true)
        elif dproot=$(find_up dprint.json || find_up dprint.jsonc); then
            bin=$(find_local_bin dprint || { command -v dprint &>/dev/null && echo dprint; }) \
                && (cd "$dproot" && "$bin" fmt "$FILE_PATH" 2>/dev/null || true)
        else
            PROJECT_ROOT=$(find_up package.json) || PROJECT_ROOT="$FILE_DIR"
            if command -v npx &>/dev/null; then
                (cd "$PROJECT_ROOT" && npx prettier --write "$FILE_PATH" 2>/dev/null || true)
            fi
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
