#!/bin/bash

input=$(cat)

cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
session_name=$(echo "$input" | jq -r '.session_name // empty')
model_display=$(echo "$input" | jq -r '.model.display_name // empty')

status=""

# Directory (blue)
if [ -n "$cwd" ]; then
    dir_name=$(basename "$cwd")
    status+=$(printf '\033[34m%s\033[0m' "$dir_name")
fi

# Git branch (dimmed)
if [ -n "$cwd" ] && git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(cd "$cwd" && git branch --show-current 2>/dev/null)
    if [ -n "$branch" ]; then
        status+=$(printf ' \033[90m%s\033[0m' "$branch")
    fi

    # Dirty indicator (cyan)
    git_status=$(cd "$cwd" && git -c core.useBuiltinFSMonitor=false status --porcelain 2>/dev/null)
    if [ -n "$git_status" ]; then
        status+=$(printf ' \033[36m*\033[0m')
    fi

    # Ivadolabs indicator
    git_email=$(cd "$cwd" && git config user.email 2>/dev/null)
    if echo "$git_email" | grep -q "ivadolabs"; then
        status+=$(printf ' \033[2m\033[37mil\033[0m')
    fi
fi

# Python venv (dimmed)
if [ -n "$VIRTUAL_ENV" ]; then
    venv_name=$(basename "$VIRTUAL_ENV")
    status+=$(printf ' \033[90m%s\033[0m' "$venv_name")
fi

# Session name or model
if [ -n "$session_name" ]; then
    status+=$(printf ' \033[35m[%s]\033[0m' "$session_name")
elif [ -n "$model_display" ]; then
    model_short=$(echo "$model_display" | sed 's/Claude //' | sed 's/ Sonnet//')
    status+=$(printf ' \033[2m\033[37m%s\033[0m' "$model_short")
fi

echo "$status"
