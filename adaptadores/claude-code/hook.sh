#!/usr/bin/env bash
# Adaptador Claude Code (PreToolUse, matcher Bash): JSON de Claude → reglas/evaluar.sh → JSON de Claude.
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cmd=$(jq -r '.tool_input.command // ""')
IFS=$'\t' read -r d m < <("$KIT/reglas/evaluar.sh" "$cmd")
[[ "$d" == allow ]] && exit 0
jq -n --arg d "$d" --arg m "$m" \
  '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:$d,permissionDecisionReason:$m}}'
