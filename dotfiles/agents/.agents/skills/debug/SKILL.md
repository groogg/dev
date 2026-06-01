---
name: debug
description: Use when debugging. Adds logger.debug statements to trace execution without modifying logic.
---

# Debug Skill

You are to debug the specified function using only `logger.debug()` statements (loguru).

## Rules

- Do NOT modify any existing logic, control flow, or data
- Add `logger.debug()` statements that reveal:
  - Function entry with all argument values
  - Key variable state at decision points (if/else, match)
  - Loop iterations with relevant index/value
  - Return values just before each return
- Add `from loguru import logger` if not already imported
- If you believe you've found a bug, add a comment on the line above: `# BUG?: <explanation>`
- Do not add logs inside hot loops unless the loop is small or bounded
- Use f-strings for all formatting

## Cleanup

When the user asks to clean up debug logs, review each `logger.debug()` you added:
- **Keep** logs that provide useful observability (function entry/exit, key state transitions)
- **Remove** logs that are too granular or only useful for the immediate debugging session
- Do not remove `# BUG?:` comments — those should stay until the user addresses them
