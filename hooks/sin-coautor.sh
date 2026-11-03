#!/usr/bin/env bash
# PreToolUse (Bash): niega commits, PRs o MRs que lleven atribución de IA.
# Cubre Claude y Cursor (cursor-agent agrega su Co-authored-by solo).
set -uo pipefail
cmd=$(jq -r '.tool_input.command // ""')
if grep -qiE 'co-authored-by:[[:space:]]*(claude|cursor)|generated with \[?claude code|cursoragent@cursor\.com' <<<"$cmd"; then
  jq -n '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",
    permissionDecisionReason:"Atribución de IA prohibida en commits, PRs y MRs. Sacá esa línea y volvé a intentar."}}'
fi
exit 0
