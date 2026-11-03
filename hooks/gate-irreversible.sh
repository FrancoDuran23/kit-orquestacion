#!/usr/bin/env bash
# PreToolUse (Bash): lo reversible pasa solo; lo irreversible le pregunta a una persona.
# Regla del método: los gates van únicamente donde no hay vuelta atrás.
set -uo pipefail
cmd=$(jq -r '.tool_input.command // ""')

motivo=""
if   grep -qE '(^|[;&|[:space:]])git[[:space:]]+push\b' <<<"$cmd"; then motivo="git push publica en el remoto"
elif grep -qE '(^|[;&|[:space:]])(gh[[:space:]]+pr|glab[[:space:]]+mr)[[:space:]]+merge\b' <<<"$cmd"; then motivo="mergea en el remoto"
elif grep -qE '(^|[;&|[:space:]])git[[:space:]]+reset[[:space:]]+--hard\b' <<<"$cmd"; then motivo="git reset --hard descarta trabajo"
elif grep -qE '(^|[;&|[:space:]])git[[:space:]]+clean[[:space:]]+-[a-zA-Z]*f' <<<"$cmd"; then motivo="git clean borra archivos sin trackear"
elif grep -qE '(^|[;&|[:space:]])git[[:space:]]+branch[[:space:]]+-D\b' <<<"$cmd"; then motivo="borra una rama sin mergear"
elif grep -qE '(^|[;&|[:space:]])rm[[:space:]]+-[a-zA-Z]*r[a-zA-Z]*f?[[:space:]]+(/|~|\$HOME)([[:space:]]|$)' <<<"$cmd"; then motivo="rm -r sobre / o el home"
elif grep -qiE '\b(drop[[:space:]]+(database|schema|table)|truncate[[:space:]]+table)\b' <<<"$cmd"; then motivo="borra datos de una base"
elif grep -qE '(^|[;&|[:space:]])(gh|glab)[[:space:]]+(issue|pr|mr)[[:space:]]+(comment|note|create)\b' <<<"$cmd"; then motivo="publica algo visible para el equipo"
fi

if [[ -n "$motivo" ]]; then
  jq -n --arg m "Gate: $motivo. Confirmá antes de seguir." \
    '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"ask",permissionDecisionReason:$m}}'
fi
exit 0
