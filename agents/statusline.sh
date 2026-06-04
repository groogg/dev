#!/usr/bin/env bash
# Claude Code statusline — shows token count and context usage percentage
# Receives JSON session data on stdin from Claude Code

read -r input
tokens=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
pct=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# Format token count (e.g. 57500 → 57.5k)
if [ "$tokens" -ge 1000000 ]; then
  formatted=$(awk "BEGIN {printf \"%.1fM\", $tokens/1000000}")
elif [ "$tokens" -ge 1000 ]; then
  formatted=$(awk "BEGIN {printf \"%.1fk\", $tokens/1000}")
else
  formatted="$tokens"
fi

# Bold yellow output
printf "\033[1;33m%s (%.1f%%)\033[0m" "$formatted" "$pct"
