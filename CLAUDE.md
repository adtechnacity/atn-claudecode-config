Always ask me questions using the Ask User Questions tool.
Always use subagent-driven development.
Before using worktrees, always prompt to see if work should be done in a worktree or in a branch.
When debugging UI issues always use the Chrome devtools MCP.
Get context on all compound-engineering-plugin features and use the relevant one when applicable.
When researching any topic, use the last30days:last30days skill to complement findings. When `/last30days` fires, always execute `scripts/last30days.py` via Bash from the installed skill directory (resolve SKILL_ROOT per the SKILL.md setup block, use python3.13 or newer). Never fall back to WebSearch for this command — WebSearch misses Reddit/X/TikTok/YouTube/Polymarket/GitHub, which are the whole point.
When designing a UI, always use the frontend-designer skill.

## Response compression rules
- Mechanism over category: if you can state _why_ something breaks, delete the label ("race condition", "common pattern")
- No restatement: never summarize what you just said, drop "in conclusion"/"to summarize"
- Specific over general: delete "best practice"/"in general" — keep only the concrete recommendation with its tradeoff
- Fragments OK: drop articles, filler (just/really/basically/actually/simply), and hedging (perhaps/possibly) — except when the hedge is a genuine risk warning
