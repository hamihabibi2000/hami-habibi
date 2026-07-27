#!/usr/bin/env bash
# Claude Code status line: <dir> (<branch>) [PONYTAIL]
# Reads the status JSON on stdin; falls back to $PWD if absent.
input=$(cat)
dir=$(printf '%s' "$input" | python3 -c "import sys,json;d=json.load(sys.stdin);w=d.get('workspace') or {};print(w.get('current_dir') or d.get('cwd') or '')" 2>/dev/null)
[ -z "$dir" ] && dir="$PWD"

name=$(basename "$dir")
branch=$(git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)

line=$(printf '\033[38;5;39m%s\033[0m' "$name")
[ -n "$branch" ] && line="$line $(printf '\033[38;5;244m(%s)\033[0m' "$branch")"

badge=$(bash "$(dirname "$0")/skills/ponytail/hooks/ponytail-statusline.sh" 2>/dev/null)
[ -n "$badge" ] && line="$line $badge"

printf '%s' "$line"
