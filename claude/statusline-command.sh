#!/bin/bash

# Read JSON input from stdin
input=$(cat)

# Extract model display name and current directory
model=$(echo "$input" | jq -r '.model.display_name')
cwd=$(echo "$input" | jq -r '.workspace.current_dir')

# Get git branch (skip optional locks)
git_branch=""
if git -C "$cwd" rev-parse --git-dir > /dev/null 2>&1; then
    git_branch=$(git -C "$cwd" --no-optional-locks branch --show-current 2>/dev/null)
    if [ -n "$git_branch" ]; then
        git_branch=" (${git_branch})"
    fi
fi

# Build compact token usage bar (% of context window used this session)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

if [ -n "$used_pct" ]; then
    used_pct_int=$(printf "%.0f" "$used_pct")

    # Build a 10-char bar: each char = 10%
    bar_width=10
    filled=$(( used_pct_int * bar_width / 100 ))
    [ "$filled" -gt "$bar_width" ] && filled=$bar_width
    empty=$(( bar_width - filled ))

    bar=""
    for i in $(seq 1 $filled); do bar="${bar}█"; done
    for i in $(seq 1 $empty);  do bar="${bar}░"; done

    # Color the bar: green <50%, yellow 50-79%, red >=80%
    if [ "$used_pct_int" -ge 80 ]; then
        bar_color="\033[31m"
    elif [ "$used_pct_int" -ge 50 ]; then
        bar_color="\033[33m"
    else
        bar_color="\033[32m"
    fi

    # Single line: model + git branch + token bar
    printf "\033[36m%s\033[0m\033[33m%s\033[0m  ctx ${bar_color}%s\033[0m %d%%" \
        "$model" "$git_branch" "$bar" "$used_pct_int"
else
    # Single line: model + git branch + empty bar
    printf "\033[36m%s\033[0m\033[33m%s\033[0m  ctx \033[90m%s\033[0m --" \
        "$model" "$git_branch" "░░░░░░░░░░"
fi
