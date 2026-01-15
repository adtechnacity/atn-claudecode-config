#!/bin/bash
set -euo pipefail

# Prevents editing very large files that might cause issues

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# Get file size
if [[ "$OSTYPE" == "darwin"* ]]; then
  SIZE=$(stat -f%z "$FILE_PATH" 2>/dev/null || echo 0)
else
  SIZE=$(stat -c%s "$FILE_PATH" 2>/dev/null || echo 0)
fi

# Block files over 1MB
if [ "$SIZE" -gt 1048576 ]; then
  echo "BLOCKED: File is too large (${SIZE} bytes)." >&2
  echo "Consider editing a smaller portion or using a different approach." >&2
  exit 2
fi

# Warn for files over 100KB
if [ "$SIZE" -gt 102400 ]; then
  echo "WARNING: Large file (${SIZE} bytes). Edits may be slow." >&2
fi

exit 0
