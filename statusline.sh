#!/bin/bash
# Claude Code status line script
# Reads JSON session data from stdin and outputs a formatted status bar

INPUT=$(cat)

if [[ -z "$INPUT" ]]; then
    echo "no-branch | unknown | Context: 0% [░░░░░░░░░░░░░░░░░░░░] | \$0.00"
    exit 0
fi

# Extract fields using jq
# model is an object like {"id": "claude-opus-4-6", "display_name": "Opus 4.6"}
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // .model // "unknown"' 2>/dev/null)
MODEL="${MODEL:-unknown}"

USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' 2>/dev/null | cut -d. -f1)
USED_PCT="${USED_PCT//[^0-9]/}"
USED_PCT="${USED_PCT:-0}"

COST=$(echo "$INPUT" | jq -r '.cost.total // 0' 2>/dev/null)
COST="${COST:-0}"

# Git branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "no-branch")
BRANCH="${BRANCH:-no-branch}"

# Clamp percentage to 0-100
USED_PCT=$((USED_PCT > 100 ? 100 : USED_PCT))

# Build progress bar (20 chars wide)
FILLED=$(( USED_PCT / 5 ))
EMPTY=$(( 20 - FILLED ))
BAR=$(printf '%0.s█' $(seq 1 $FILLED 2>/dev/null) ; printf '%0.s░' $(seq 1 $EMPTY 2>/dev/null))

# Format cost
if [[ "$COST" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    COST_FMT=$(printf '$%.2f' "$COST")
else
    COST_FMT='$0.00'
fi

echo "$BRANCH | $MODEL | Context: ${USED_PCT}% [${BAR}] | ${COST_FMT}"
