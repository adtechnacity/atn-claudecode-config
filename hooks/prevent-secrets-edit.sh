#!/bin/bash
# Claude Code Hook: Prevent editing sensitive files
# Type: PreToolUse (Edit, Write)
# Purpose: Block accidental edits to files containing secrets or credentials

set -euo pipefail

# Parse JSON input from stdin (Claude Code hook protocol)
input=$(cat)
FILE_PATH=$(echo "$input" | jq -r '.tool_input.file_path // empty')

# Exit early if no file path provided
if [[ -z "$FILE_PATH" ]]; then
    exit 0
fi

# Patterns that indicate sensitive files
SENSITIVE_PATTERNS=(
    ".env"
    ".env.local"
    ".env.production"
    ".env.development"
    "credentials"
    "secrets"
    ".pem"
    ".key"
    ".p12"
    ".pfx"
    "serviceAccount"
    "service-account"
    "id_rsa"
    "id_ed25519"
    "id_ecdsa"
    ".keystore"
    "keystore.json"
    "wallet.json"
    "private_key"
    "private-key"
    "secret_key"
    "secret-key"
)

# Check if file path matches any sensitive pattern
for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    if [[ "$FILE_PATH" == *"$pattern"* ]]; then
        echo "BLOCKED: Cannot edit potentially sensitive file: $FILE_PATH"
        echo ""
        echo "This file matches the sensitive pattern: '$pattern'"
        echo ""
        echo "If this edit is intentional:"
        echo "  1. View the file with 'cat $FILE_PATH'"
        echo "  2. Edit it manually outside Claude Code"
        echo "  3. Or temporarily disable this hook"
        exit 2
    fi
done

# Allow the operation
exit 0
