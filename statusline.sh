#!/bin/bash
# Claude Code status line script
# Reads JSON session data from stdin and outputs a formatted status bar

INPUT=$(cat)

# Extract fields using jq
# model is an object like {"id": "claude-opus-4-6", "display_name": "Opus 4.6"}
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // .model // "unknown"')
USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
COST=$(echo "$INPUT" | jq -r '.cost.total // 0')

# Git branch
BRANCH=$(git branch --show-current 2>/dev/null || echo "no-branch")

# Build progress bar (20 chars wide)
FILLED=$(( USED_PCT / 5 ))
EMPTY=$(( 20 - FILLED ))
BAR=$(printf '%0.s█' $(seq 1 $FILLED 2>/dev/null) ; printf '%0.s░' $(seq 1 $EMPTY 2>/dev/null))

# Format cost
COST_FMT=$(printf '$%.2f' "$COST")

echo "$BRANCH | $MODEL | Context: ${USED_PCT}% [${BAR}] | ${COST_FMT}"
