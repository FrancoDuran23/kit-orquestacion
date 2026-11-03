#!/usr/bin/env bash
# Adaptador Codex CLI, evento PreToolUse con matcher ^Bash$.
# Entrada: {"tool_input":{"command":"..."}} · Salida: hookSpecificOutput (deny) o nada (allow).
# Codex no soporta "ask" (lo toma como falla y ejecuta igual): lo irreversible se niega.
KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cmd=$(jq -r '.tool_input.command // ""')
IFS=$'\t' read -r d m < <("$KIT/reglas/evaluar.sh" "$cmd")
[[ "$d" == allow ]] && exit 0
[[ "$d" == ask ]] && m="$m (Codex no puede preguntar en un hook: pedile a la persona que lo corra)"
jq -n --arg m "$m" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$m}}'
