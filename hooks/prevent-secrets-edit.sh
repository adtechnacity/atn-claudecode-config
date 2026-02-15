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

# Get basename for precise matching (avoids false positives on paths like credentials-helper.ts)
BASENAME=$(basename "$FILE_PATH")

# Safe patterns to allow (templates, examples)
SAFE_PATTERNS=(".env.example" ".env.sample" ".env.template")
for safe in "${SAFE_PATTERNS[@]}"; do
    if [[ "$BASENAME" == "$safe" ]]; then
        exit 0
    fi
done

# Block .env files (catch .env, .env.local, .env.production, .env.*)
if [[ "$BASENAME" =~ ^\.env($|\.) ]]; then
    echo "BLOCKED: Cannot edit potentially sensitive file: $FILE_PATH"
    echo "This file matches a .env pattern."
    echo ""
    echo "If this edit is intentional:"
    echo "  1. View the file with 'cat $FILE_PATH'"
    echo "  2. Edit it manually outside Claude Code"
    echo "  3. Or temporarily disable this hook"
    exit 2
fi

# Exact basename matches for known sensitive files
SENSITIVE_BASENAMES=(
    "credentials.json" "secrets.json"
    "serviceAccount.json" "service-account.json"
    "keystore.json" "wallet.json"
    "id_rsa" "id_ed25519" "id_ecdsa"
)
for pattern in "${SENSITIVE_BASENAMES[@]}"; do
    if [[ "$BASENAME" == "$pattern" ]]; then
        echo "BLOCKED: Cannot edit potentially sensitive file: $FILE_PATH"
        echo "This file matches the sensitive pattern: '$pattern'"
        echo ""
        echo "If this edit is intentional:"
        echo "  1. View the file with 'cat $FILE_PATH'"
        echo "  2. Edit it manually outside Claude Code"
        echo "  3. Or temporarily disable this hook"
        exit 2
    fi
done

# Extension-based matches (checked on basename to avoid path false positives)
SENSITIVE_EXTENSIONS=(".pem" ".key" ".p12" ".pfx" ".keystore")
for ext in "${SENSITIVE_EXTENSIONS[@]}"; do
    if [[ "$BASENAME" == *"$ext" ]]; then
        echo "BLOCKED: Cannot edit potentially sensitive file: $FILE_PATH"
        echo "This file matches the sensitive extension: '$ext'"
        echo ""
        echo "If this edit is intentional:"
        echo "  1. View the file with 'cat $FILE_PATH'"
        echo "  2. Edit it manually outside Claude Code"
        echo "  3. Or temporarily disable this hook"
        exit 2
    fi
done

# Basename substring matches (catch variants like private_key.pem)
SENSITIVE_SUBSTRINGS=("private_key" "private-key" "secret_key" "secret-key")
for pattern in "${SENSITIVE_SUBSTRINGS[@]}"; do
    if [[ "$BASENAME" == *"$pattern"* ]]; then
        echo "BLOCKED: Cannot edit potentially sensitive file: $FILE_PATH"
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
